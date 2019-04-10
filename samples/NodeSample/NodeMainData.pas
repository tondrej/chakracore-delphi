(*

MIT License

Copyright (c) 2019 Ondrej Kelle

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*)

unit NodeMainData;

interface

{$include common.inc}

uses
{$ifdef FPC}{$ifdef UNIX}
  cwstring,
{$endif}{$endif}
{$ifdef WINDOWS}
  Windows,
{$endif}
  SysUtils, Classes, Contnrs,
{$ifdef HAS_WIDESTRUTILS}
  WideStrUtils,
{$endif}
  Compat, ChakraCommon, ChakraCore, ChakraCoreUtils, ChakraCoreClasses,
  Console, NodeProcess;

type
  TNodeModule = class
  private
    FFileName: UnicodeString;
    FHandle: JsvalueRef;
    FParent: TNodeModule;
    FRequire: JsValueRef;
  public
    constructor Create(AParent: TNodeModule);

    property FileName: UnicodeString read FFileName;
    property Handle: JsValueRef read FHandle;
    property Parent: TNodeModule read FParent;
    property Require: JsValueRef read FRequire;
  end;

  { TDataModuleMain }

  TDataModuleMain = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FBaseDir: UnicodeString;
    FConsole: TConsole;
    FContext: TChakraCoreContext;
    FMainModule: TNodeModule;
    FModules: TObjectList;
    FNodeBaseDir: UnicodeString;
    FProcess: TProcess;
    FRuntime: TChakraCoreRuntime;
    FUseAnsiColors: Boolean;

    procedure ConsoleLog(Sender: TObject; const Text: UnicodeString; Level: TInfoLevel = ilNone);
    procedure ContextActivate(Sender: TObject);
    procedure ContextLoadModule(Sender: TObject; Module: TChakraModule);
    procedure ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
    function FindModule(ARequire: JsValueRef): TNodeModule; overload;
    function FindModule(const AFileName: UnicodeString): TNodeModule; overload;
    procedure LoadModule(Module: TNodeModule; const FileName: UnicodeString);
    function LoadPackage(const FileName: UnicodeString): JsValueRef;
    function Require(CallerModule: TNodeModule; const Path: UnicodeString): JsValueRef;
    function Resolve(const Request, CurrentPath: UnicodeString): UnicodeString;
    function ResolveDirectory(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
    function ResolveFile(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
    function ResolveIndex(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
    function ResolveModules(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
    function RunModule(Module: TNodeModule): JsValueRef;
  public
    procedure Execute(const FileName: UnicodeString);

    property BaseDir: UnicodeString read FBaseDir;
    property Console: TConsole read FConsole;
    property Context: TChakraCoreContext read FContext;
    property NodeBaseDir: UnicodeString read FNodeBaseDir;
    property Runtime: TChakraCoreRuntime read FRuntime;
    property UseAnsiColors: Boolean read FUseAnsiColors write FUseAnsiColors;
  end;

implementation

{$R *.dfm}

function JsInspectHandler(Value: JsValueRef; E: Exception): UnicodeString;
begin
  Result := WideFormat('[%s] %s', [E.ClassName, E.Message]);
end;

function CombinePath(const Path, Name: UnicodeString): UnicodeString;
begin
  Result := IncludeTrailingPathDelimiter(Path) + Name;
end;

function ParentPath(const Path: UnicodeString): UnicodeString;
begin
  Result := ExtractFilePath(ExcludeTrailingPathDelimiter(Path));
end;

function LoadFile(const FileName: UnicodeString): UnicodeString;
var
  FileStream: TFileStream;
  S: UTF8String;
begin
  Result := '';

  FileStream := TFileStream.Create(UTF8String(FileName), fmOpenRead);
  try
    if FileStream.Size = 0 then
      Exit;

    SetLength(S, FileStream.Size);
    FileStream.Read(S[1], FileStream.Size);

    Result := UTF8ToString(S);
  finally
    FileStream.Free;
  end;
end;

function PostTimedTask(Args: PJsValueRefArray; ArgCount: Word; CallbackState: Pointer; RepeatCount: Integer): JsValueRef;
var
  DataModule: TDataModuleMain absolute CallbackState;
  AMessage: TTaskMessage;
  Delay: Cardinal;
  FuncArgs: array[0..0] of JsValueRef;
  I: Integer;
begin
  Result := JsUndefinedValue;

  if ArgCount < 2 then // thisarg, function to call, optional: delay, function args
    raise Exception.Create('Invalid arguments');

  if ArgCount >= 3 then
    Delay := JsNumberToInt(Args^[2])
  else
    Delay := 0;

  if ArgCount >= 4 then
  begin
    for I := 0 to ArgCount - 4 do
      FuncArgs[I] := Args^[I + 3];
  end;

  AMessage := TTaskMessage.Create(DataModule.Context, Args^[1], Args^[0], FuncArgs, Delay, RepeatCount);
  try
    DataModule.Context.PostMessage(AMessage);
  except
    AMessage.Free;
    raise;
  end;
end;

function Require_Callback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  DataModule: TDataModuleMain absolute CallbackState;
  CallerModule: TNodeModule;
  Path: UnicodeString;
begin
  Result := JsUndefinedValue;
  try
    if ArgCount <> 2 then
      raise Exception.Create('require: module name not specified');

    if JsGetValueType(Args^[1]) <> JsString then
      raise Exception.Create('require: module name not a string value');

    CallerModule := DataModule.FindModule(Callee);
    Path := JsStringToUnicodeString(Args^[1]);
    if PathDelim <> '/' then
      Path := UnicodeStringReplace(Path, '/', PathDelim, [rfReplaceAll]);

    Result := DataModule.Require(CallerModule, Path);
  except
    on E: EChakraCoreScript do
      JsThrowError(WideFormat('%s (%d, %d): [%s] %s', [E.ScriptURL, E.Line + 1, E.Column + 1, E.ClassName, E.Message]));
    on E: Exception do
      JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function SetInterval_Callback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := PostTimedTask(Args, ArgCount, CallbackState, -1); // repeat endlessly
end;

function SetTimeout_Callback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := PostTimedTask(Args, ArgCount, CallbackState, 1); // run once
end;

type
  THackPromiseMessage = class(TPromiseMessage);

  TDummyPromiseThread = class(TThread)
  private
    FMessage: TPromiseMessage;
    FTimeout: Cardinal;
    FValue: JsValueRef;
  protected
    procedure Execute; override;
  public
    constructor Create(AMessage: TPromiseMessage; ATimeout: Cardinal);
  end;

{ TTestPromiseThread }

procedure TDummyPromiseThread.Execute;
begin
  Sleep(FTimeout);
  THackPromiseMessage(FMessage).SetStatus(psResolved, FValue);
end;

constructor TDummyPromiseThread.Create(AMessage: TPromiseMessage; ATimeout: Cardinal);
begin
  FMessage := AMessage;
  FTimeout := ATimeout;
  FValue := StringToJsString('Success!');
  JsAddRef(FValue);
  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TDataModuleMain.ConsoleLog(Sender: TObject; const Text: UnicodeString; Level: TInfoLevel);
const
  StartBlocks: array[TInfoLevel] of RawByteString = ('', #$1b'[32;1m', #$1b'[33;1m', #$1b'[31;1m');
  EndBlocks: array[Boolean] of RawByteString = ('', #$1b'[0m');
{$ifdef WINDOwS}
  BackgroundMask = $F0;
  TextColors: array[TInfoLevel] of Word = (0, FOREGROUND_GREEN or FOREGROUND_INTENSITY,
    FOREGROUND_GREEN or FOREGROUND_RED or FOREGROUND_INTENSITY, FOREGROUND_RED or FOREGROUND_INTENSITY);
{$endif}
var
{$ifdef WINDOWS}
  Info: TConsoleScreenBufferInfo;
{$endif}
  S: UTF8String;
begin
  S := UTF8Encode(Text);
{$ifdef WINDOWS}
  if UseAnsiColors then
    Writeln(StartBlocks[Level], S, EndBlocks[Level <> ilNone])
  else
  begin
    if (Level = ilNone) or not GetConsoleScreenBufferInfo(TTextRec(Output).Handle, Info) then
    begin
      Writeln(S);
      Exit;
    end;

    SetConsoleTextAttribute(TTextRec(Output).Handle, Info.wAttributes and BackgroundMask or TextColors[Level]);
    try
      Writeln(S);
    finally
      SetConsoleTextAttribute(TTextRec(Output).Handle, Info.wAttributes);
    end;
  end;
{$else}
  Writeln(StartBlocks[Level], S, EndBlocks[Level <> ilNone]);
{$endif}
end;

procedure TDataModuleMain.ContextActivate(Sender: TObject);
begin
  // expose global.console
  FConsole := TConsole.Create;
  FConsole.OnLog := ConsoleLog;
  JsSetProperty(FContext.Global, 'console', FConsole.Instance);

  // expose additional functions
  JsSetCallback(FContext.Global, 'setTimeout', @SetTimeout_Callback, Self);
  JsSetCallback(FContext.Global, 'setInterval', @SetInterval_Callback, Self);

  FProcess := TProcess.Create;
  JsSetProperty(FContext.Global, 'process', FProcess.Instance);

  JsSetCallback(FContext.Global, 'require', @Require_Callback, Self);
end;

procedure TDataModuleMain.ContextLoadModule(Sender: TObject; Module: TChakraModule);
begin
  // TODO ES6 modules
end;

procedure TDataModuleMain.ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
begin
  if NativeObject is TConsole then
    TConsole(NativeObject).OnLog := ConsoleLog;
end;

function TDataModuleMain.FindModule(ARequire: JsValueRef): TNodeModule;
var
  I: Integer;
begin
  Result := nil;

  for I := 0 to FModules.Count - 1 do
    if TNodeModule(FModules[I]).Require = ARequire then
    begin
      Result := TNodeModule(FModules[I]);
      Break;
    end;
end;

function TDataModuleMain.FindModule(const AFileName: UnicodeString): TNodeModule;
var
  I: Integer;
begin
  Result := nil;

  for I := 0 to FModules.Count - 1 do
    if WideSameText(AFileName, TNodeModule(FModules[I]).FileName) then
    begin
      Result := TNodeModule(FModules[I]);
      Break;
    end;
end;

procedure TDataModuleMain.LoadModule(Module: TNodeModule; const FileName: UnicodeString);
var
  WrapScript: UnicodeString;
begin
  if ExtractFileExt(FileName) = '.json' then
    WrapScript := '(function (exports, require, module, __filename, __dirname) {' + sLineBreak +
      'module.exports = ' + LoadFile(FileName) + ';' + sLineBreak + '})'
  else
    WrapScript := '(function (exports, require, module, __filename, __dirname) {' + sLineBreak +
      LoadFile(FileName) + sLineBreak + '})';
  Module.FFileName := FileName;
  Module.FHandle := FContext.RunScript(WrapScript, FileName);
  JsSetProperty(Module.Handle, 'exports', JsCreateObject);
  JsSetProperty(Module.Handle, '__dirname', StringToJsString(ExtractFilePath(FileName)));
  JsSetProperty(Module.Handle, '__filename', StringToJsString(FileName));
  Module.FRequire := JsSetCallback(Module.Handle, 'require', @Require_Callback, Self);

  ConsoleLog(FConsole, WideFormat('Loaded module ''%s''', [ExtractRelativePath(FBaseDir, Module.FileName)]), ilInfo);
end;

function TDataModuleMain.LoadPackage(const FileName: UnicodeString): JsValueRef;
begin
  Result := FContext.CallFunction('parse', [StringToJsString(LoadFile(FileName))], JsGetProperty(JsGlobal, 'JSON'));
end;

function TDataModuleMain.Require(CallerModule: TNodeModule; const Path: UnicodeString): JsValueRef;
var
  FileName: UnicodeString;
  Module: TNodeModule;
begin
  if Assigned(CallerModule) then
    FileName := Resolve(Path, ExtractFilePath(CallerModule.FileName))
  else
    FileName := Resolve(Path, FBaseDir);

  if FileName = '' then
    raise Exception.CreateFmt('Module ''%s'' not found', [Path]);

  FileName := ExpandFileName(FileName);

  Module := FindModule(FileName);
  if not Assigned(Module) then
  begin
    Module := TNodeModule.Create(CallerModule);
    try
      FModules.Add(Module);
      LoadModule(Module, FileName);
      RunModule(Module);
    except
      on E: Exception do
      begin
        if Module <> FMainModule then
          FModules.Remove(Module);
        raise;
      end;
    end;
  end;
  
  Result := JsGetProperty(Module.Handle, 'exports');
end;

function TDataModuleMain.Resolve(const Request, CurrentPath: UnicodeString): UnicodeString;
var
  BasePaths: array[0..1] of UnicodeString;
  SRequest: UnicodeString;
  I: Integer;
begin
  Result := '';
  if Request = '' then
    Exit;

  if Request[1] = '/' then
    BasePaths[0] := {$ifdef MSWINDOWS}ExtractFileDrive(CurrentPath){$else}''{$endif};
  if (Request[1] = PathDelim) or
    ((Length(Request) > 1) and (Request[1] = '.') and (Request[2] = PathDelim)) or
    ((Length(Request) > 2) and (Request[1] = '.') and (Request[2] = '.') and (Request[3] = PathDelim)) then
    BasePaths[0] := CurrentPath;
  BasePaths[1] := ExtractFilePath(ParamStr(0)) + '..' + PathDelim + '..' + PathDelim + '..' + PathDelim +
    'ext' + PathDelim + 'node' + PathDelim + 'lib';

  SRequest := Request;
  if PathDelim <> '/' then
    SRequest := UnicodeStringReplace(SRequest, '/', PathDelim, [rfReplaceAll]);

  for I := Low(BasePaths) to High(BasePaths) do
  begin
    if ResolveFile(IncludeTrailingPathDelimiter(BasePaths[I]) + SRequest, Result) then
      Exit;
    if ResolveDirectory(IncludeTrailingPathDelimiter(BasePaths[I]) + SRequest, Result) then
      Exit;
  end;

  if not ResolveModules(Request, Result) then
    Result := '';
end;

function TDataModuleMain.ResolveDirectory(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
var
  Package, Main: UnicodeString;
begin
  FileName := '';

  Package := IncludeTrailingPathDelimiter(Request) + 'package.json';
  if FileExists(Package) then
  begin
    Main := IncludeTrailingPathDelimiter(Request) + JsStringToUnicodeString(JsGetProperty(LoadPackage(Package), 'main'));
    if PathDelim <> '/' then
      Main := UnicodeStringReplace(Main, '/', PathDelim, [rfReplaceAll]);

    Result := ResolveFile(Main, FileName) or ResolveIndex(Main, FileName);
    if Result then
      Exit;
  end;

  Result := ResolveIndex(Request, FileName);
end;

function TDataModuleMain.ResolveFile(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
begin
  Result := False;
  FileName := '';

  if FileExists(Request) and not DirectoryExists(Request) then
  begin
    FileName := Request;
    Result := True;
  end
  else if FileExists(Request + '.js') then
  begin
    FileName := Request + '.js';
    Result := True;
  end
  else if FileExists(Request + '.json') then
  begin
    FileName := Request + '.json';
    Result := True;
  end
  else if FileExists(Request + '.node') then
  begin
    FileName := Request + '.node';
    Result := True;
  end;
end;

function TDataModuleMain.ResolveIndex(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
begin
  Result := False;
  FileName := '';

  if FileExists(IncludeTrailingPathDelimiter(Request) + 'index.js') then
  begin
    FileName := IncludeTrailingPathDelimiter(Request) + 'index.js';
    Result := True;
  end
  else if FileExists(IncludeTrailingPathDelimiter(Request) + 'index.json') then
  begin
    FileName := IncludeTrailingPathDelimiter(Request) + 'index.json';
    Result := True;
  end
  else if FileExists(IncludeTrailingPathDelimiter(Request) + 'index.node') then
  begin
    FileName := IncludeTrailingPathDelimiter(Request) + 'index.node';
    Result := True;
  end
end;

function TDataModuleMain.ResolveModules(const Request: UnicodeString; out FileName: UnicodeString): Boolean;
var
  NodeModulePaths: array of UnicodeString;
  I: Integer;
begin
  Result := False;
  FileName := '';

  // TODO global paths etc.
  SetLength(NodeModulePaths, 1);
  NodeModulePaths[0] := IncludeTrailingPathDelimiter(FBaseDir) + 'node_modules';

  for I := 0 to High(NodeModulePaths) do
  begin
    Result := ResolveFile(IncludeTrailingPathDelimiter(NodeModulePaths[I]) + Request, FileName);
    if Result then
      Break;
    Result := ResolveDirectory(IncludeTrailingPathDelimiter(NodeModulePaths[I]) + Request, FileName);
    if Result then
      Break;
  end;
end;

function TDataModuleMain.RunModule(Module: TNodeModule): JsValueRef;
begin
  FContext.CallFunction(Module.Handle, [JsGetProperty(Module.Handle, 'exports'), Module.Require, Module.Handle,
    StringToJsString(Module.FileName), StringToJsString(ExtractFilePath(Module.FileName))], Module.Handle);
  Result := JsGetProperty(Module.Handle, 'exports');
end;

procedure TDataModuleMain.DataModuleCreate(Sender: TObject);
begin
  try
    JsInspectExceptionHandler := JsInspectHandler;
    FRuntime := TChakraCoreRuntime.Create([ccroEnableExperimentalFeatures, ccroDispatchSetExceptionsToDebugger]);
    FContext := TChakraCoreContext.Create(FRuntime);
    FContext.OnActivate := ContextActivate;
    FContext.OnLoadModule := ContextLoadModule;
    FContext.OnNativeObjectCreated := ContextNativeObjectCreated;
    FBaseDir := UTF8Decode(GetCurrentDir);
    FModules := TObjectList.Create;
  except
    FreeAndNil(FConsole);
    FreeAndNil(FContext);
    FreeAndNil(FRuntime);
    raise;
  end;
end;

procedure TDataModuleMain.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FConsole);
  FreeAndNil(FProcess);
  FreeAndNil(FModules);
  FreeAndNil(FContext);
  FreeAndNil(FRuntime);
end;

procedure TDataModuleMain.Execute(const FileName: UnicodeString);
var
  FullFileName: UnicodeString;
begin
  FullFileName := ExpandFileName(FileName);
  FBaseDir := ExtractFilePath(FullFileName);

  FMainModule := TNodeModule.Create(nil);
  try
    FModules.Add(FMainModule);
    LoadModule(FMainModule, FullFileName);
    RunModule(FMainModule);
  except
    FModules.Remove(FMainModule);
    FMainModule := nil;
    raise;
  end;
end;

{ TNodeModule public }

constructor TNodeModule.Create(AParent: TNodeModule);
begin
  inherited Create;
  FParent := AParent;
end;

end.
