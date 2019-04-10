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

unit ChakraCoreHostMainData;

interface

{$include common.inc}

uses
{$ifdef FPC}{$ifdef UNIX}
  cwstring,
{$endif}{$endif}
{$ifdef WINDOWS}
  Windows,
{$endif}
  SysUtils, Classes,
{$ifdef HAS_WIDESTRUTILS}
  WideStrUtils,
{$endif}
  Compat, ChakraCommon, ChakraCore, ChakraCoreUtils, ChakraCoreClasses, Console;

type

  { TDataModuleMain }

  TDataModuleMain = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FBaseDir: UnicodeString;
    FConsole: TConsole;
    FContext: TChakraCoreContext;
    FRuntime: TChakraCoreRuntime;
    FUseAnsiColors: Boolean;

    procedure ConsoleLog(Sender: TObject; const Text: UnicodeString; Level: TInfoLevel = ilNone);
    procedure ContextActivate(Sender: TObject);
    procedure ContextLoadModule(Sender: TObject; Module: TChakraModule);
    procedure ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
  public
    procedure Execute(const ScriptFileNames: array of UnicodeString);

    property BaseDir: UnicodeString read FBaseDir;
    property Console: TConsole read FConsole;
    property Context: TChakraCoreContext read FContext;
    property Runtime: TChakraCoreRuntime read FRuntime;
    property UseAnsiColors: Boolean read FUseAnsiColors write FUseAnsiColors;
  end;

implementation

{$R *.dfm}

function LoadFile(const FileName: UnicodeString): UnicodeString;
var
  FileStream: TFileStream;
  S: UTF8String;
begin
  Result := '';

{$ifdef UNICODE}
  FileStream := TFileStream.Create(FileName, fmOpenRead);
{$else}
  FileStream := TFileStream.Create(UTF8Encode(FileName), fmOpenRead);
{$endif}
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

function TestPromise_Callback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray;
  ArgCount: Word; CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  DataModule: TDataModuleMain absolute CallbackState;
  AMessage: TPromiseMessage;
  ResolveTask, RejectTask: JsValueRef;
begin
  if ArgCount <> 2 then // thisarg, timeout
    raise Exception.Create('Invalid arguments');

  JsCreatePromise(Result, ResolveTask, RejectTask);
  AMessage := TPromiseMessage.Create(DataModule.Context, Args^[0], ResolveTask, RejectTask);
  try
    TDummyPromiseThread.Create(AMessage, JsNumberToInt(Args^[1]));
    DataModule.Context.PostMessage(AMessage);
  except
    AMessage.Free;
    raise;
  end;
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
  // expose additional functions
  JsSetCallback(FContext.Global, 'setTimeout', @SetTimeout_Callback, Self, True);
  JsSetCallback(FContext.Global, 'setInterval', @SetInterval_Callback, Self, True);
  JsSetCallback(FContext.Global, 'testPromise', @TestPromise_Callback, Self, True);

  // project TConsole class so scripts can create instances, e.g. var c = new Console();
  TConsole.Project;

  // expose global.console
  FConsole := TConsole.Create;
  JsSetProperty(FContext.Global, 'console', FConsole.Instance);
end;

procedure TDataModuleMain.ContextLoadModule(Sender: TObject; Module: TChakraModule);
var
  ModuleFileName: UnicodeString;
begin
  ModuleFileName := IncludeTrailingPathDelimiter(FBaseDir) + ChangeFileExt(Module.Name, UnicodeString('.js'));
  if FileExists(ModuleFileName) then
  begin
    Module.Parse(LoadFile(ModuleFileName));
    Module.URL := WideFormat('file://%s/%s', [ChangeFileExt(ExtractFileName(ParamStr(0)), UnicodeString('')),
      ChangeFileExt(Module.Name, UnicodeString('.js'))]);
  end;
end;

procedure TDataModuleMain.ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
begin
  if NativeObject is TConsole then
    TConsole(NativeObject).OnLog := ConsoleLog;
end;

procedure TDataModuleMain.DataModuleCreate(Sender: TObject);
begin
  try
    FRuntime := TChakraCoreRuntime.Create([ccroEnableExperimentalFeatures, ccroDispatchSetExceptionsToDebugger]);
    FContext := TChakraCoreContext.Create(FRuntime);
    FContext.OnActivate := ContextActivate;
    FContext.OnLoadModule := ContextLoadModule;
    FContext.OnNativeObjectCreated := ContextNativeObjectCreated;
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
  FreeAndNil(FContext);
  FreeAndNil(FRuntime);
end;

procedure TDataModuleMain.Execute(const ScriptFileNames: array of UnicodeString);
var
  I: Integer;
begin
  for I := Low(ScriptFileNames) to High(ScriptFileNames) do
  begin
    FBaseDir := ExtractFilePath(ScriptFileNames[I]);
    FContext.RunScript(LoadFile(ScriptFilenames[I]), UnicodeString(ExtractFileName(ScriptFileNames[I])));
  end;
end;

end.
