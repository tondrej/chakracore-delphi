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

unit WasmMainData;

interface

{$include common.inc}

uses
{$ifdef FPC}{$ifdef UNIX}
  cwstring,
{$endif}{$endif}
{$ifdef WINDOWS}
  Windows,
{$endif}
{$ifdef FPC}
  LCLIntf, LCLType,
{$endif}
  SysUtils, Classes, Forms, Graphics, Dialogs,
{$ifdef HAS_WIDESTRUTILS}
  WideStrUtils,
{$endif}
  Compat, ChakraCommon, ChakraCore, ChakraCoreUtils, ChakraCoreClasses, Console;

type

  { TDataModuleMain }

  TDataModuleMain = class(TDataModule)
    OpenDialog: TOpenDialog;

    procedure DataModuleCreate(Sender: TObject);
  private
    FCanvas: JsValueRef;
    FConsole: TConsole;
    FContext: TChakraCoreContext;
    FRuntime: TChakraCoreRuntime;
    FScriptFileName: UnicodeString;
    FTerminated: Boolean;
    FThread: TThread;
    FWasmFileName: UnicodeString;

    procedure ConsoleLog(Sender: TObject; const Text: UnicodeString; Level: TInfoLevel = ilNone);
    procedure ContextActivate(Sender: TObject);
    procedure ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
    procedure Finalize;
    function GetActive: Boolean;
    procedure Initialize;
    function LoadWasmModule(const FileName: UnicodeString): JsValueRef;
    procedure RunScript;
    procedure SetActive(Value: Boolean);
  public
    property Active: Boolean read GetActive write SetActive;
    property ScriptFileName: UnicodeString read FScriptFileName;
  end;

var
  DataModuleMain: TDataModuleMain;

implementation

{$R *.dfm}

uses
  WasmMainForm;

type

  { TTaskMessageEx }

  TTaskMessageEx = class(TTaskMessage)
  private
    FDataModule: TDataModuleMain;
  protected
    function Process(out ResultValue: JsValueRef): Boolean; override;
  end;

  function TTaskMessageEx.Process(out ResultValue: JsValueRef): Boolean;
  begin
    Result := FDataModule.FTerminated or inherited Process(ResultValue);
  end;

type

  { TWasmThread }

  TWasmThread = class(TThread)
  private
    FDataModule: TDataModuleMain;
  protected
    procedure Execute; override;
  public
    constructor Create(ADataModule: TDataModuleMain);
    destructor Destroy; override;
  end;

constructor TWasmThread.Create(ADataModule: TDataModuleMain);
begin
  FDataModule := ADataModule;
  FDataModule.FThread := Self;
  FreeOnTerminate := True;
  inherited Create(False);
end;

destructor TWasmThread.Destroy;
begin
  FDataModule.FThread := nil;
  inherited Destroy;
end;

procedure TWasmThread.Execute;
begin
  FDataModule.Initialize;
  try
    FDataModule.RunScript;
  finally
    FDataModule.Finalize;
  end;
end;

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
  AMessage: TTaskMessageEx;
  Delay: Cardinal;
  FuncArgs: JsValueRefArray;
begin
  Result := JsUndefinedValue;
  if DataModule.FTerminated then
    Exit;

  // arg 0: thisarg
  // arg 1: task
  if ArgCount < 2 then
    raise Exception.Create('Invalid arguments');

  // arg 2: (optional) delay
  if ArgCount >= 3 then
    Delay := JsNumberToInt(Args^[2])
  else
    Delay := 0;

  // arg 3...: (optional) function args
  FuncArgs := nil;
  if ArgCount >= 4 then
  begin
    SetLength(FuncArgs, ArgCount - 3);
    Move(Args^[3], FuncArgs[0], (ArgCount - 3) * SizeOf(JsValueRef));
  end;

  AMessage := TTaskMessageEx.Create(DataModule.FContext, Args^[1], Args^[0], FuncArgs, Delay, RepeatCount);
  try
    AMessage.FDataModule := DataModule;
    DataModule.FContext.PostMessage(AMessage);
  except
    AMessage.Free;
    raise;
  end;
end;

function Canvas_FillRect_Callback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := JsUndefinedValue;
  try
    FormMain.FillRect(JsNumberToInt(Args^[1]), JsNumberToInt(Args^[2]), JsNumbertoInt(Args^[3]), JsNumberToInt(Args^[4]),
      JsStringToUTF8String(JsGetProperty(Args^[0], 'fillStyle')));
  except on E: Exception do
    JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function LoadWasm_Callback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  DataModule: TDataModuleMain absolute CallbackState;
begin
  Result := JsUndefinedValue;
  try
    DataModule.FWasmFileName := ExtractFilePath(DataModule.FScriptFileName) + JsStringToUnicodeString(Args^[1]);
    Result := DataModule.LoadWasmModule(DataModule.FWasmFileName);
  except on E: Exception do
    JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function SetInterval_Callback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := JsUndefinedValue;
  try
    Result := PostTimedTask(Args, ArgCount, CallbackState, -1); // repeat endlessly
  except on E: Exception do
    JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function SetTimeout_Callback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := JsUndefinedValue;
  try
    Result := PostTimedTask(Args, ArgCount, CallbackState, 1); // run once
  except on E: Exception do
    JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

procedure TDataModuleMain.DataModuleCreate(Sender: TObject);
begin
  FScriptFileName := ParamStr(1);
end;

procedure TDataModuleMain.ConsoleLog(Sender: TObject; const Text: UnicodeString; Level: TInfoLevel);
var
  P: PAnsiChar;
begin
  P := StrNew(PAnsiChar(UTF8Encode(Text)));
  try
    PostMessage(FormMain.Handle, WM_CONSOLELOG, WPARAM(P), 0);
  except
    StrDispose(P);
    raise;
  end;
end;

procedure TDataModuleMain.ContextActivate(Sender: TObject);
begin
  // expose additional functions
  JsSetCallback(FContext.Global, 'setTimeout', @SetTimeout_Callback, Self);
  JsSetCallback(FContext.Global, 'setInterval', @SetInterval_Callback, Self);
  JsSetCallback(FContext.Global, 'loadWasm', @LoadWasm_Callback, Self);

  // project TConsole class so scripts can create instances, e.g. var c = new Console();
  TConsole.Project;

  // expose global.console
  FConsole := TConsole.Create;
  JsSetProperty(FContext.Global, 'console', FConsole.Instance);

  FCanvas := JsCreateObject;
  JsSetProperty(FCanvas, 'fillStyle', StringToJsString('black'));
  JsSetCallback(FCanvas, 'fillRect', @Canvas_FillRect_Callback, Self);
  JsSetProperty(FContext.Global, 'ctx', FCanvas);
end;

procedure TDataModuleMain.ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
begin
  if NativeObject is TConsole then
    TConsole(NativeObject).OnLog := ConsoleLog;
end;

function TDataModuleMain.LoadWasmModule(const FileName: UnicodeString): JsValueRef;
var
  Buffer: TChakraCoreNativeArrayBuffer;
  FileStream: TFileStream;
begin
  Result := JsUndefinedValue;

  FileStream := TFileStream.Create(FileName, fmOpenRead);
  try
    Buffer := TChakraCoreNativeArrayBuffer.Create(FileStream.Size);
    try
      FileStream.ReadBuffer(Buffer.Buffer^, Buffer.BufferSize);
      Result := Buffer.Handle;
      ConsoleLog(FConsole, Format('Loaded WebAssembly file ''%s''', [FWasmFileName]));
    except
      Buffer.Free;
      raise;
    end;
  finally
    FileStream.Free;
  end;
end;

procedure TDataModuleMain.RunScript;
var
  Script: UnicodeString;
begin
  try
    Script := LoadFile(FScriptFileName);
    ConsoleLog(FConsole, Format('Loaded Javascript file ''%s''', [FScriptFileName]));
    FContext.RunScript(Script, FScriptFileName);
  except
    on E: EChakraCoreScript do
      ConsoleLog(FConsole, Format('%s (%d, %d): [%s] %s', [E.ScriptURL, E.Line + 1, E.Column + 1, E.ClassName,
        E.Message]));
    on E: Exception do
      ConsoleLog(FConsole, Format('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

procedure TDataModuleMain.Finalize;
begin
  FreeAndNil(FConsole);
  FreeAndNil(FContext);
  FreeAndNil(FRuntime);
end;

function TDataModuleMain.GetActive: Boolean;
begin
  Result := Assigned(FThread);
end;

procedure TDataModuleMain.Initialize;
begin
  FRuntime := TChakraCoreRuntime.Create([ccroEnableExperimentalFeatures, ccroDispatchSetExceptionsToDebugger]);
  FContext := TChakraCoreContext.Create(FRuntime);
  FContext.OnActivate := ContextActivate;
  FContext.OnNativeObjectCreated := ContextNativeObjectCreated;
end;

procedure TDataModuleMain.SetActive(Value: Boolean);
begin
  if Value <> Active then
  begin
    FTerminated := not Value;
    if Value then
    begin
      if FScriptFileName = '' then
      begin
        OpenDialog.FileName := '';
        if OpenDialog.Execute then
          FScriptFileName := OpenDialog.FileName;
      end;
      FThread := TWasmThread.Create(Self);
    end;
  end;
end;

end.
