(*

MIT License

Copyright (c) 2018 Ondrej Kelle

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

unit ChakraCoreClasses;

{$include common.inc}

interface

uses
{$ifndef SUPPORTS_CLASS_FIELDS}
  Windows,
{$endif}
  Classes, SysUtils, Contnrs,
  Compat, ChakraCore, ChakraCommon;

type
  TChakraCoreContext = class;
  TChakraModule = class;

  TMemAllocEvent = procedure (Sender: TObject; Size: NativeUInt; var Allow: Boolean) of object;
  TMemFreeEvent = procedure (Sender: TObject; Size: NativeUInt) of object;
  TMemFailureEvent = procedure (Sender: TObject; Size: NativeUInt) of object;

  TChakraCoreRuntimeOption = (
    ccroDisableBackgroundWork,           // JsRuntimeAttributeDisableBackgroundWork           = $00000001;
    ccroAllowScriptInterrupt,            // JsRuntimeAttributeAllowScriptInterrupt            = $00000002;
    ccroEnableIdleProcessing,            // JsRuntimeAttributeEnableIdleProcessing            = $00000004;
    ccroDisableNativeCodeGeneration,     // JsRuntimeAttributeDisableNativeCodeGeneration     = $00000008;
    ccroDisableEval,                     // JsRuntimeAttributeDisableEval                     = $00000010;
    ccroEnableExperimentalFeatures,      // JsRuntimeAttributeEnableExperimentalFeatures      = $00000020;
    ccroDispatchSetExceptionsToDebugger, // JsRuntimeAttributeDispatchSetExceptionsToDebugger = $00000040;
    ccroDisableFatalOnOOM                // JsRuntimeAttributeDisableFatalOnOOM               = $00000080;
  );
  TChakraCoreRuntimeOptions = set of TChakraCoreRuntimeOption;

  TChakraCoreRuntime = class
  private
    FHandle: JsRuntimeHandle;
    FMemoryLimit: NativeUInt;
    FOptions: TChakraCoreRuntimeOptions;

    FOnBeforeCollect: TNotifyEvent;
    FOnMemAlloc: TMemAllocEvent;
    FOnMemFailure: TMemFailureEvent;
    FOnMemFree: TMemFreeEvent;

    function GetEnabled: Boolean;
    function GetHandle: JsRuntimeHandle;
    function GetMemoryLimit: NativeUInt;
    function GetMemoryUsage: NativeUInt;
    procedure SetEnabled(Value: Boolean);
    procedure SetMemoryLimit(Value: NativeUInt);

    procedure SetOnBeforeCollect(Value: TNotifyEvent);
    procedure SetOnMemAlloc(Value: TMemAllocEvent);
    procedure SetOnMemFailure(Value: TMemFailureEvent);
    procedure SetOnMemFree(Value: TMemFreeEvent);
  protected
    procedure CreateRuntime; virtual;
    procedure DisposeRuntime; virtual;
    procedure DoBeforeCollect; virtual;
    function DoMemAlloc(Size: NativeUInt): Boolean; virtual;
    procedure DoMemFailure(Size: NativeUInt); virtual;
    procedure DoMemFree(Size: NativeUInt); virtual;
  public
    constructor Create(AOptions: TChakraCoreRuntimeOptions = []); virtual;
    destructor Destroy; override;

    procedure CollectGarbage;

    property Enabled: Boolean read GetEnabled write SetEnabled;
    property Handle: JsRuntimeHandle read GetHandle;
    property MemoryLimit: NativeUInt read GetMemoryLimit write SetMemoryLimit;
    property MemoryUsage: NativeUInt read GetMemoryUsage;
    property Options: TChakraCoreRuntimeOptions read FOptions;

    property OnBeforeCollect: TNotifyEvent read FOnBeforeCollect write SetOnBeforeCollect;
    property OnMemAlloc: TMemAllocEvent read FOnMemAlloc write SetOnMemAlloc;
    property OnMemFailure: TMemFailureEvent read FOnMemFailure write SetOnMemFailure;
    property OnMemFree: TMemFreeEvent read FOnMemFree write SetOnMemFree;
  end;

  TBaseMessage = class
  private
    FContext: TChakraCoreContext;
  protected
    function Process: JsValueRef; virtual; abstract;
  public
    constructor Create(AContext: TChakraCoreContext); virtual;

    property Context: TChakraCoreContext read FContext;
  end;

  TCallbackMessage = class(TBaseMessage)
  private
    FTask: JsValueRef;
  protected
    function Process: JsValueRef; override;
  public
    constructor Create(AContext: TChakraCoreContext; ATask: JsValueRef); reintroduce; virtual;
    destructor Destroy; override;

    property Task: JsValueRef read FTask;
  end;

  TModuleMessage = class(TBaseMessage)
  private
    FModule: TChakraModule;
  protected
    function Process: JsValueRef; override;
  public
    constructor Create(AContext: TChakraCoreContext; AModule: TChakraModule); reintroduce; virtual;

    property Module: TChakraModule read FModule;
  end;

  { TChakraModule }

  TChakraModule = class
  private
    FContext: TChakraCoreContext;
    FHandle: JsModuleRecord;
    FName: UnicodeString;
    FParsed: Boolean;
    FResult: JsvalueRef;
    FSpecifier: JsValueRef;
  public
    constructor Create(AContext: TChakraCoreContext; const AName: UnicodeString; ARefModule: JsModuleRecord);
    destructor Destroy; override;

    procedure Parse(const Source: UTF8String); overload;
    procedure Parse(const Source: UnicodeString); overload;

    property Context: TChakraCoreContext read FContext;
    property Handle: JsModuleRecord read FHandle;
    property Name: UnicodeString read FName;
    property Parsed: Boolean read FParsed;
    property Result: JsValueRef read FResult;
    property Specifier: JsValueRef read FSpecifier;
  end;

  TLoadModuleEvent = procedure(Sender: TObject; Module: TChakraModule) of object;

  { TChakraCoreContext }

  TChakraCoreContext = class
  private
    FGlobal: JsValueRef;
    FHandle: JsContextRef;
    FMessageQueue: TQueue;
    FModules: TStringList;
    FName: UnicodeString;
    FRuntime: TChakraCoreRuntime;
    FSourceContext: NativeUInt;

    FOnLoadModule: TLoadModuleEvent;

    function GetData: Pointer;
    function GetHandle: JsContextRef;
    function GetGlobal: JsValueRef;
    function GetModuleCount: Integer;
    function GetModuleNames(Index: Integer): UnicodeString;
    function GetModules(Index: Integer): TChakraModule;
    procedure SetData(Value: Pointer);
  protected
    procedure ClearModules;
    function CreateModule(const AName: UnicodeString; ARefModule: JsModuleRecord): TChakraModule; virtual;
    procedure DoLoadModule(Module: TChakraModule); virtual;
    procedure DoPromiseContinuation(Task: JsValueRef); virtual;
    function HandleFetchImportedModuleCallback(referencingModule: JsModuleRecord; specifier: JsValueRef;
      out dependentModuleRecord: JsModuleRecord): JsErrorCode; virtual;
    function HandleFetchImportedModuleFromScriptCallback(dwReferencingSourceContext: JsSourceContext; specifier: JsValueRef;
      out dependentModuleRecord: JsModuleRecord): JsErrorCode; virtual;
    function HandleNotifyModuleReadyCallback(referencingModule: JsModuleRecord; exceptionVar: JsValueRef): JsErrorCode; virtual;
    function ModuleNeeded(const AName: UnicodeString; ARefModule: JsModuleRecord = nil): TChakraModule;

    procedure ProcessMessages;
  public
    constructor Create(ARuntime: TChakraCoreRuntime);
    destructor Destroy; override;

    procedure Activate;
    procedure AddModule(const AName: UTF8String); overload;
    procedure AddModule(const AName: UnicodeString); overload;
    function CallFunction(const AName: UTF8String; const Args: array of JsValueRef; Instance: JsValueRef = nil): JsValueRef;
    class function CurrentContext: TChakraCoreContext;
    function FindModule(const AName: UnicodeString): TChakraModule; overload;
    function FindModule(AHandle: JsModuleRecord): TChakraModule; overload;
    function RunScript(const Script, AName: UTF8String): JsValueRef; overload;
    function RunScript(const Script, AName: UnicodeString): JsValueRef; overload;

    property Data: Pointer read GetData write SetData;
    property Global: JsValueRef read GetGlobal;
    property Handle: JsContextRef read GetHandle;
    property ModuleCount: Integer read GetModuleCount;
    property ModuleNames[Index: Integer]: UnicodeString read GetModuleNames;
    property Modules[Index: Integer]: TChakraModule read GetModules;
    property Name: UnicodeString read FName;
    property Runtime: TChakraCoreRuntime read FRuntime;

    property OnLoadModule: TLoadModuleEvent read FOnLoadModule write FOnLoadModule;
  end;

  TChakraCoreNativeClass = class of TChakraCoreNativeObject;

  TChakraCoreNativeMethod = function (Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef of object;

  TChakraCoreNativeObject = class
  private
    FInstance: JsValueRef;
{$ifdef SUPPORTS_CLASS_FIELDS}
    class var Prototype: JsValueRef;
{$endif}

    function GetContextHandle: JsContextRef;
  protected
{$ifndef SUPPORTS_CLASS_FIELDS}
    class function Prototype: JsValueRef;
{$endif}
    class procedure RegisterMethod(AInstance: JsValueRef; const AName: UnicodeString; AMethod: Pointer;
      UseStrictRules: Boolean = True); virtual;
    class procedure RegisterMethods(AInstance: JsValueRef); virtual; abstract;
  public
    constructor Create(Arguments: PJsValueRef = nil; ArgumentCount: Word = 0); virtual;
    destructor Destroy; override;

    class procedure Project(const AName: UnicodeString = ''; UseStrictRules: Boolean = True);

    property ContextHandle: JsContextRef read GetContextHandle;
    property Instance: JsValueRef read FInstance;
  end;

implementation

uses
  ChakraCoreUtils;

{$ifndef SUPPORTS_CLASS_FIELDS}
type
  PProjectedClassInfo = ^TProjectedClassInfo;
  TProjectedClassInfo = record
    AClass: TChakraCoreNativeClass;
    APrototype: JsValueRef;
  end;

var
  Lock: TRTLCriticalSection;
  ProjectedClasses: TList = nil;

function AddPrototype(AClass: TChakraCoreNativeClass; APrototype: JsValueRef = nil): Integer;
var
  Info: PProjectedClassInfo;
begin
  if not Assigned(APrototype) then
    ChakraCoreCheck(JsCreateObject(APrototype));

  GetMem(Info, SizeOf(TProjectedClassInfo));
  try
    Info^.AClass := AClass;
    Info^.APrototype := APrototype;

    Result := ProjectedClasses.Add(Info);
  except
    FreeMem(Info);
    raise;
  end;
end;

function FindPrototype(AClass: TChakraCoreNativeClass): JsValueRef;
var
  I: Integer;
begin
  Result := nil;

  EnterCriticalSection(Lock);
  try
    for I := 0 to ProjectedClasses.Count - 1 do
      if PProjectedClassInfo(ProjectedClasses[I])^.AClass = AClass then
      begin
        Result := PProjectedClassInfo(ProjectedClasses[I])^.APrototype;
        Break;
      end;
  finally
    LeaveCriticalSection(Lock);
  end;
end;

procedure InitializeProjectedClasses;
begin
  InitializeCriticalSection(Lock);

  EnterCriticalSection(Lock);
  try
    ProjectedClasses := TList.Create;
  finally
    LeaveCriticalSection(Lock);
  end;
end;

procedure FinalizeProjectedClasses;
var
  I: Integer;
begin
  EnterCriticalSection(Lock);
  try
    for I := 0 to ProjectedClasses.Count - 1 do
      FreeMem(ProjectedClasses[I]);
    FreeAndNil(ProjectedClasses);
  finally
    LeaveCriticalSection(Lock);
    DeleteCriticalSection(Lock);
  end;
end;

{$endif}

procedure BeforeCollectCallback(callbackState: Pointer); {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  if Assigned(callbackState) then
    TChakraCoreRuntime(callbackState).DoBeforeCollect;
end;

function ThreadServiceCallback(callback: JsBackgroundWorkItemCallback; callbackState: Pointer): bool; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := False; // let ChakraCore handle this work item

  // TODO
  // Result := True;
  // CurrentRuntime.DoBackgroundWork(callback, callbackState);
end;

function FetchImportedModuleCallBack(referencingModule: JsModuleRecord; specifier: JsValueRef;
  out dependentModuleRecord: JsModuleRecord): JsErrorCode; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := TChakraCoreContext.CurrentContext.HandleFetchImportedModuleCallback(referencingModule, specifier, dependentModuleRecord);
end;

function FetchImportedModuleFromScriptCallBack(dwReferencingSourceContext: JsSourceContext; specifier: JsValueRef;
  out dependentModuleRecord: JsModuleRecord): JsErrorCode; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := TChakraCoreContext.CurrentContext.HandleFetchImportedModuleFromScriptCallback(dwReferencingSourceContext, specifier,
    dependentModuleRecord);
end;

function MemoryAllocationCallback(callbackState: Pointer; allocationEvent: JsMemoryEventType; allocationSize: size_t): bool;
  {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := True;

  if Assigned(callbackState) then
    case allocationEvent of
      JsMemoryAllocate:
        Result := TChakraCoreRuntime(callbackState).DoMemAlloc(allocationSize);
      JsMemoryFree:
        TChakraCoreRuntime(callbackState).DoMemFree(allocationSize);
      JsMemoryFailure:
        TChakraCoreRuntime(callbackState).DoMemFailure(allocationSize);
    end;
end;

function NativeClass_ConstructorCallback(Callee: JsValueRef; IsConstructCall: bool; Arguments: PJsValueRef; ArgumentCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  NativeClass: TChakraCoreNativeClass absolute CallbackState;
  NativeInstance: TChakraCoreNativeObject;
begin
  Result := JsUndefinedValue;
  try
    Inc(Arguments);
    Dec(ArgumentCount);

    NativeInstance := NativeClass.Create(Arguments, ArgumentCount);
    Result := NativeInstance.Instance;
  except on E: Exception do
    JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function NativeClass_MethodCallback(Callee: JsValueRef; IsConstructCall: bool; Arguments: PJsValueRef; ArgumentCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  NativeMethod: TChakraCoreNativeMethod;
begin
  Result := JsUndefinedValue;
  try
    if not Assigned(Arguments) or (ArgumentCount = 0) then
      raise Exception.Create('Invalid arguments');

    if (JsGetValueType(Arguments^) <> JsObject) then
      raise Exception.Create('thisarg not an object');

    TMethod(NativeMethod).Code := CallbackState;
    TMethod(NativeMethod).Data := JsGetExternalData(Arguments^);

    if Arguments^ <> TChakraCoreNativeObject(TMethod(NativeMethod).Data).Instance then
      raise Exception.Create('thisarg not the registered instance');

    Inc(Arguments);
    Dec(ArgumentCount);

    Result := NativeMethod(Arguments, ArgumentCount);
  except
    on E: Exception do
      JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

procedure NativeClass_FinalizeCallback(data: Pointer); {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  TObject(data).Free;
end;

function NotifyModuleReadyCallback(referencingModule: JsModuleRecord; exceptionVar: JsValueRef): JsErrorCode;
  {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := TChakraCoreContext.CurrentContext.HandleNotifyModuleReadyCallback(referencingModule, exceptionVar);
end;

function RuntimeOptionsToJsRuntimeAttributes(Value: TChakraCoreRuntimeOptions): Cardinal;
begin
  Result := JsRuntimeAttributeNone;
  if ccroDisableBackgroundWork in Value then
    Result := Result or JsRuntimeAttributeDisableBackgroundWork;
  if ccroAllowScriptInterrupt in Value then
    Result := Result or JsRuntimeAttributeAllowScriptInterrupt;
  if ccroEnableIdleProcessing in Value then
    Result := Result or JsRuntimeAttributeEnableIdleProcessing;
  if ccroDisableNativeCodeGeneration in Value then
    Result := Result or JsRuntimeAttributeDisableNativeCodeGeneration;
  if ccroDisableEval in Value then
    Result := Result or JsRuntimeAttributeDisableEval;
  if ccroEnableExperimentalFeatures in Value then
    Result := Result or JsRuntimeAttributeEnableExperimentalFeatures;
  if ccroDispatchSetExceptionsToDebugger in Value then
    Result := Result or JsRuntimeAttributeDispatchSetExceptionsToDebugger;
  if ccroDisableFatalOnOOM in Value then
    Result := Result or JsRuntimeAttributeDisableFatalOnOOM;
end;

{ TChakraCoreRuntime private }

function TChakraCoreRuntime.GetEnabled: Boolean;
var
  Disabled: ByteBool;
begin
  if FHandle = JS_INVALID_RUNTIME_HANDLE then
    Result := False
  else
  begin
    ChakraCoreCheck(JsIsRuntimeExecutionDisabled(FHandle, Disabled));
    Result := not Disabled;
  end;
end;

function TChakraCoreRuntime.GetHandle: JsRuntimeHandle;
begin
  if FHandle = JS_INVALID_RUNTIME_HANDLE then
    CreateRuntime;
  Result := FHandle;
end;

function TChakraCoreRuntime.GetMemoryLimit: NativeUInt;
begin
  if FHandle <> JS_INVALID_RUNTIME_HANDLE then
    ChakraCoreCheck(JsGetRuntimeMemoryLimit(FHandle, FMemoryLimit));
  Result := FMemoryLimit;
end;

function TChakraCoreRuntime.GetMemoryUsage: NativeUInt;
begin
  Result := 0;
  if FHandle <> JS_INVALID_RUNTIME_HANDLE then
    ChakraCoreCheck(JsGetRuntimeMemoryUsage(FHandle, Result));
end;

procedure TChakraCoreRuntime.SetEnabled(Value: Boolean);
begin
  if Value <> Enabled then
  begin
    if Value then
      ChakraCoreCheck(JsEnableRuntimeExecution(Handle))
    else
      ChakraCoreCheck(JsDisableRuntimeExecution(Handle));
  end;
end;

procedure TChakraCoreRuntime.SetMemoryLimit(Value: NativeUInt);
begin
  if Value <> FMemoryLimit then
  begin
    if FHandle <> JS_INVALID_RUNTIME_HANDLE then
      ChakraCoreCheck(JsSetRuntimeMemoryLimit(FHandle, Value));

    FMemoryLimit := Value;
  end;
end;

procedure TChakraCoreRuntime.SetOnBeforeCollect(Value: TNotifyEvent);
begin
  if @Value <> @FOnBeforeCollect then
  begin
    FOnBeforeCollect := Value;
  end;
end;

procedure TChakraCoreRuntime.SetOnMemAlloc(Value: TMemAllocEvent);
begin
  if @Value <> @FOnMemAlloc then
  begin
    if FHandle <> JS_INVALID_RUNTIME_HANDLE then
    begin
      if Assigned(Value) or Assigned(FOnMemFailure) or Assigned(FOnMemFree) then
        ChakraCoreCheck(JsSetRuntimeMemoryAllocationCallback(FHandle, Self, MemoryAllocationCallback))
      else
        ChakraCoreCheck(JsSetRuntimeMemoryAllocationCallback(FHandle, Self, nil));
    end;

    FOnMemAlloc := Value;
  end;
end;

procedure TChakraCoreRuntime.SetOnMemFailure(Value: TMemFailureEvent);
begin
  if @Value <> @FOnMemFailure then
  begin
    if FHandle <> JS_INVALID_RUNTIME_HANDLE then
    begin
      if Assigned(Value) or Assigned(FOnMemAlloc) or Assigned(FOnMemFree) then
        ChakraCoreCheck(JsSetRuntimeMemoryAllocationCallback(FHandle, Self, MemoryAllocationCallback))
      else
        ChakraCoreCheck(JsSetRuntimeMemoryAllocationCallback(FHandle, Self, nil));
    end;

    FOnMemFailure := Value;
  end;
end;

procedure TChakraCoreRuntime.SetOnMemFree(Value: TMemFreeEvent);
begin
  if @Value <> @FOnMemFree then
  begin
    if FHandle <> JS_INVALID_RUNTIME_HANDLE then
    begin
      if Assigned(Value) or Assigned(FOnMemAlloc) or Assigned(FOnMemFailure) then
        ChakraCoreCheck(JsSetRuntimeMemoryAllocationCallback(FHandle, Self, MemoryAllocationCallback))
      else
        ChakraCoreCheck(JsSetRuntimeMemoryAllocationCallback(FHandle, Self, nil));
    end;

    FOnMemFree := Value;
  end;
end;

{ TChakraCoreRuntime protected }

procedure TChakraCoreRuntime.CreateRuntime;
begin
  if FHandle <> JS_INVALID_RUNTIME_HANDLE then
    Exit;

  ChakraCoreCheck(JsCreateRuntime(JsRuntimeAttributes(RuntimeOptionsToJsRuntimeAttributes(FOptions)),
    ThreadServiceCallback, FHandle));
  try
    if NativeInt(FMemoryLimit) <> -1 then
      ChakraCoreCheck(JsSetRuntimeMemoryLimit(FHandle, FMemoryLimit));
    if Assigned(FOnMemAlloc) or Assigned(FOnMemFailure) or Assigned(FOnMemFree) then
      ChakraCoreCheck(JsSetRuntimeMemoryAllocationCallback(FHandle, Self, MemoryAllocationCallback));
    if Assigned(FOnBeforeCollect) then
      ChakraCoreCheck(JsSetRuntimeBeforeCollectCallback(FHandle, Self, BeforeCollectCallback));
  except
    JsDisposeRuntime(FHandle);
    FHandle := JS_INVALID_RUNTIME_HANDLE;
    raise;
  end;
end;

procedure TChakraCoreRuntime.DisposeRuntime;
begin
  if FHandle = JS_INVALID_RUNTIME_HANDLE then
    Exit;

  ChakraCoreCheck(JsSetCurrentContext(JS_INVALID_REFERENCE));
  ChakraCoreCheck(JsSetRuntimeMemoryAllocationCallback(FHandle, Self, nil));
  ChakraCoreCheck(JsDisposeRuntime(FHandle));
  FHandle := JS_INVALID_RUNTIME_HANDLE;
end;

procedure TChakraCoreRuntime.DoBeforeCollect;
begin
  if Assigned(FOnBeforeCollect) then
    FOnBeforeCollect(Self);
end;

function TChakraCoreRuntime.DoMemAlloc(Size: NativeUInt): Boolean;
begin
  Result := True;
  if Assigned(FOnMemAlloc) then
    FOnMemAlloc(Self, Size, Result);
end;

procedure TChakraCoreRuntime.DoMemFailure(Size: NativeUInt);
begin
  if Assigned(FOnMemFailure) then
    FOnMemFailure(Self, Size);
end;

procedure TChakraCoreRuntime.DoMemFree(Size: NativeUInt);
begin
  if Assigned(FOnMemFree) then
    FOnMemFree(Self, Size);
end;

{ TChakraCoreRuntime public }

constructor TChakraCoreRuntime.Create(AOptions: TChakraCoreRuntimeOptions);
begin
  inherited Create;
  FHandle := JS_INVALID_RUNTIME_HANDLE;
  FMemoryLimit := NativeUInt(NativeInt(-1));
  FOnMemAlloc := nil;
  FOnMemFailure := nil;
  FOnMemFree := nil;
  FOptions := AOptions;
end;

destructor TChakraCoreRuntime.Destroy;
begin
  DisposeRuntime;
  inherited Destroy;
end;

procedure TChakraCoreRuntime.CollectGarbage;
begin
  if Enabled then
    ChakraCoreCheck(JsCollectGarbage(Handle));
end;

{ TBaseMessage public }

constructor TBaseMessage.Create(AContext: TChakraCoreContext);
begin
  inherited Create;
  FContext := AContext;
end;

{ TCallbackMessage protected }

function TCallbackMessage.Process: JsValueRef;
var
  Global: JsValueRef;
begin
  Global := Context.Global;
  Result := JsCallFunction(Task, Global);
  ChakraCoreCheck(JsRelease(Task, nil));
  FTask := nil;
end;

{ TCallbackMessage public }

constructor TCallbackMessage.Create(AContext: TChakraCoreContext; ATask: JsValueRef);
begin
  inherited Create(AContext);
  ChakraCoreCheck(JsAddRef(ATask, nil));
  FTask := ATask;
end;

destructor TCallbackMessage.Destroy;
begin
  if Assigned(FTask) then
    ChakraCoreCheck(JsRelease(FTask, nil));
  FTask := nil;
  inherited Destroy;
end;

{ TModuleMessage protected }

function TModuleMessage.Process: JsValueRef;
begin
  ChakraCoreCheck(JsModuleEvaluation(FModule.Handle, FModule.FResult));
  Result := FModule.FResult;
end;

{ TModuleMessage public }

constructor TModuleMessage.Create(AContext: TChakraCoreContext; AModule: TChakraModule);
begin
  inherited Create(AContext);
  FModule := AModule;
end;

{ TChakraModule public }

constructor TChakraModule.Create(AContext: TChakraCoreContext; const AName: UnicodeString;
  ARefModule: JsModuleRecord);
begin
  inherited Create;
  FContext := AContext;
  if AName = '' then
    FSpecifier := JS_INVALID_REFERENCE
  else
  begin
    FSpecifier := StringToJsString(AName);
    ChakraCoreCheck(JsAddRef(FSpecifier, nil));
  end;
  FName := AName;
  FResult := JsUndefinedValue;

  ChakraCoreCheck(JsInitializeModuleRecord(ARefModule, FSpecifier, FHandle));
  ChakraCoreCheck(JsSetModuleHostInfo(FHandle, JsModuleHostInfo_FetchImportedModuleCallback, @FetchImportedModuleCallback));
  ChakraCoreCheck(JsSetModuleHostInfo(FHandle, JsModuleHostInfo_FetchImportedModuleFromScriptCallback, @FetchImportedModuleFromScriptCallback));
  ChakraCoreCheck(JsSetModuleHostInfo(FHandle, JsModuleHostInfo_NotifyModuleReadyCallback, @NotifyModuleReadyCallback));
  ChakraCoreCheck(JsSetModuleHostInfo(FHandle, JsModuleHostInfo_HostDefined, FSpecifier));
end;

destructor TChakraModule.Destroy;
begin
  if FSpecifier <> JS_INVALID_REFERENCE then
    ChakraCoreCheck(JsRelease(FSpecifier, nil));
  inherited Destroy;
end;

procedure TChakraModule.Parse(const Source: UTF8String);
var
  Error: JsValueRef;
begin
  if not FParsed then
  begin
    ChakraCoreCheck(JsParseModuleSource(Handle, 0, PByte(PAnsiChar(Source)), Length(Source),
      JsParseModuleSourceFlags_DataIsUTF8, Error));
    FParsed := True;
  end;
end;

procedure TChakraModule.Parse(const Source: UnicodeString);
var
  Error: JsValueRef;
begin
  if not FParsed then
  begin
    ChakraCoreCheck(JsParseModuleSource(Handle, 0, PByte(PUnicodeChar(Source)), Length(Source) * SizeOf(UnicodeChar),
      JsParseModuleSourceFlags_DataIsUTF16LE, Error));
    FParsed := True;
  end;
end;

procedure PromiseContinuation(task: JsValueRef; callbackState: Pointer); {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  if Assigned(callbackState) then
    TChakraCoreContext(callbackState).DoPromiseContinuation(task);
end;

{ TChakraCoreContext private }

function TChakraCoreContext.GetData: Pointer;
begin
  ChakraCoreCheck(JsGetContextData(FHandle, Result));
end;

function TChakraCoreContext.GetGlobal: JsValueRef;
begin
  if FGlobal = JS_INVALID_REFERENCE then
    ChakraCoreCheck(JsGetGlobalObject(FGlobal));
  Result := FGlobal;
end;

function TChakraCoreContext.GetHandle: JsContextRef;
begin
  if FHandle = JS_INVALID_REFERENCE then
  begin
    ChakraCoreCheck(JsCreateContext(FRuntime.Handle, FHandle));
    ChakraCoreCheck(JsSetContextData(FHandle, Self));
  end;
  Result := FHandle;
end;

function TChakraCoreContext.GetModuleCount: Integer;
begin
  Result := FModules.Count;
end;

function TChakraCoreContext.GetModuleNames(Index: Integer): UnicodeString;
begin
  Result := FModules[Index];
end;

function TChakraCoreContext.GetModules(Index: Integer): TChakraModule;
begin
  Result := TChakraModule(FModules.Objects[Index]);
end;

procedure TChakraCoreContext.SetData(Value: Pointer);
begin
  ChakraCoreCheck(JsSetContextData(FHandle, Value));
end;

{ TChakraCoreContext protected }

procedure TChakraCoreContext.ClearModules;
var
  I: Integer;
begin
  for I := 0 to FModules.Count - 1 do
    FModules.Objects[I].Free;
  FModules.Clear;
end;

function TChakraCoreContext.CreateModule(const AName: UnicodeString; ARefModule: JsModuleRecord): TChakraModule;
begin
  Result := TChakraModule.Create(Self, AName, ARefModule);
  try
    FModules.AddObject(AName, Result);
  except
    Result.Free;
    raise;
  end;
end;

procedure TChakraCoreContext.DoLoadModule(Module: TChakraModule);
begin
  if Assigned(FOnLoadModule) then
    FOnLoadModule(Self, Module);
end;

procedure TChakraCoreContext.DoPromiseContinuation(Task: JsValueRef);
var
  AMessage: TCallbackMessage;
begin
  AMessage := TCallbackMessage.Create(Self, Task);
  try
    FMessageQueue.Push(AMessage);
  except
    AMessage.Free;
    raise;
  end;
end;

function TChakraCoreContext.HandleFetchImportedModuleCallback(referencingModule: JsModuleRecord; specifier: JsValueRef;
  out dependentModuleRecord: JsModuleRecord): JsErrorCode;
var
  ModuleName: UnicodeString;
  Module: TChakraModule;
begin
  Result := JsNoError;
  dependentModuleRecord := JS_INVALID_REFERENCE;

  ModuleName := JsStringToUnicodeString(specifier);
  Module := ModuleNeeded(ModuleName, referencingModule);

  dependentModuleRecord := Module.Handle;
end;

function TChakraCoreContext.HandleFetchImportedModuleFromScriptCallback(dwReferencingSourceContext: JsSourceContext;
  specifier: JsValueRef; out dependentModuleRecord: JsModuleRecord): JsErrorCode;
var
  ModuleName: UnicodeString;
  Module: TChakraModule;
begin
  Result := JsNoError;
  dependentModuleRecord := JS_INVALID_REFERENCE;

  ModuleName := JsStringToUnicodeString(specifier);
  Module := ModuleNeeded(ModuleName);

  dependentModuleRecord := Module.Handle;
end;

function TChakraCoreContext.HandleNotifyModuleReadyCallback(referencingModule: JsModuleRecord; exceptionVar: JsValueRef): JsErrorCode;
var
  Module: TChakraModule;
  AMessage: TModuleMessage;
begin
  Result := JsNoError;
  if Assigned(exceptionVar) then
    RaiseError(exceptionVar);

  Module := FindModule(referencingModule);

  if Assigned(Module) then
  begin
    AMessage := TModuleMessage.Create(Self, Module);
    try
      FMessageQueue.Push(AMessage);
    except
      AMessage.Free;
      raise;
    end;
  end;
end;

function TChakraCoreContext.ModuleNeeded(const AName: UnicodeString; ARefModule: JsModuleRecord): TChakraModule;
begin
  Result := FindModule(AName);

  if not Assigned(Result) then
  begin
    Result := CreateModule(AName, ARefModule);
    if AName <> '' then
      DoLoadModule(Result);
  end;
end;

procedure TChakraCoreContext.ProcessMessages;
var
  AMessage: TBaseMessage;
begin
  while FMessageQueue.Count > 0 do
  begin
    AMessage := FMessageQueue.Pop;
    try
      AMessage.Process;
    finally
      AMessage.Free;
    end;
  end;
end;

{ TChakraCoreContext public }

constructor TChakraCoreContext.Create(ARuntime: TChakraCoreRuntime);
begin
  inherited Create;
  FMessageQueue := nil;
  FModules := nil;
  FRuntime := ARuntime;
  FHandle := JS_INVALID_REFERENCE;
  FGlobal := JS_INVALID_REFERENCE;
  FMessageQueue := TQueue.Create;
  FModules := TStringList.Create;
  FModules.Duplicates := dupError;
  FModules.Sorted := True;
  FSourceContext := 0;
end;

destructor TChakraCoreContext.Destroy;
begin
  FGlobal := JS_INVALID_REFERENCE;
  FHandle := JS_INVALID_REFERENCE;
  FRuntime := nil;
  ClearModules;
  FModules.Free;
  FMessageQueue.Free;
  inherited Destroy;
end;

procedure TChakraCoreContext.Activate;
begin
  ChakraCoreCheck(JsSetCurrentContext(Handle));
  ChakraCoreCheck(JsSetPromiseContinuationCallback(PromiseContinuation, Self));
end;

procedure TChakraCoreContext.AddModule(const AName: UTF8String);
begin
  AddModule(UTF8ToString(AName));
end;

procedure TChakraCoreContext.AddModule(const AName: UnicodeString);
begin
  Activate;
  ModuleNeeded(AName);
end;

function TChakraCoreContext.CallFunction(const AName: UTF8String; const Args: array of JsValueRef;
  Instance: JsValueRef): JsValueRef;
begin
  Result := JsCallFunction(AName, Args, Instance);
  ProcessMessages;
end;

class function TChakraCoreContext.CurrentContext: TChakraCoreContext;
var
  CurrentContext: JsContextRef;
begin
  ChakraCoreCheck(JsGetCurrentContext(CurrentContext));
  ChakraCoreCheck(JsGetContextData(CurrentContext, Pointer(Result)));
end;

function TChakraCoreContext.FindModule(const AName: UnicodeString): TChakraModule;
var
  Index: Integer;
begin
  Result := nil;

  if FModules.Find(AName, Index) then
    Result := Modules[Index];
end;

function TChakraCoreContext.FindModule(AHandle: JsModuleRecord): TChakraModule;
var
  I: Integer;
begin
  Result := nil;

  for I := 0 to ModuleCount - 1 do
    if Modules[I].Handle = AHandle then
    begin
      Result := Modules[I];
      Break;
    end;
end;

function TChakraCoreContext.RunScript(const Script, AName: UTF8String): JsValueRef;
begin
  if ModuleCount = 0 then
    AddModule('');

  FName := UTF8ToString(AName);
  Inc(FSourceContext);
  try
    Result := JsRunScript(Script, AName, FSourceContext);

    ProcessMessages;
  finally
    FName := '';
    Dec(FSourceContext);
  end;
end;

function TChakraCoreContext.RunScript(const Script, AName: UnicodeString): JsValueRef;
begin
  if ModuleCount = 0 then
    AddModule('');

  FName := AName;
  Inc(FSourceContext);
  try
    Result := JsRunScript(Script, AName, FSourceContext);

    ProcessMessages;
  finally
    FName := '';
    Dec(FSourceContext);
  end;
end;

{ TChakraCoreNativeObject private }

function TChakraCoreNativeObject.GetContextHandle: JsContextRef;
begin
  ChakraCoreCheck(JsGetContextOfObject(FInstance, Result));
end;

{ TChakraCoreNativeObject protected }

{$ifndef SUPPORTS_CLASS_FIELDS}
class function TChakraCoreNativeObject.Prototype: JsValueRef;
begin
  Result := FindPrototype(Self);
end;
{$endif}

class procedure TChakraCoreNativeObject.RegisterMethod(AInstance: JsValueRef; const AName: UnicodeString;
  AMethod: Pointer; UseStrictRules: Boolean);
begin
  JsSetCallback(AInstance, AName, NativeClass_MethodCallback, AMethod, UseStrictRules);
end;

{ TChakraCoreNativeObject public }

constructor TChakraCoreNativeObject.Create(Arguments: PJsValueRef; ArgumentCount: Word);
begin
  inherited Create;
  FInstance := nil;
  ChakraCoreCheck(JsCreateExternalObject(Self, NativeClass_FinalizeCallback, FInstance));
  JsSetExternalData(FInstance, Self);
  ChakraCoreCheck(JsSetPrototype(Instance, Prototype));
end;

destructor TChakraCoreNativeObject.Destroy;
begin
  if Assigned(FInstance) then
    JsSetExternalData(FInstance, nil);
  inherited;
end;

class procedure TChakraCoreNativeObject.Project(const AName: UnicodeString; UseStrictRules: Boolean);
var
  ConstructorName: UnicodeString;
  ConstructorFunc: JsValueRef;
begin
  ConstructorName := AName;
  if ConstructorName = '' then
    ConstructorName := UnicodeString(ClassName);
  ChakraCoreCheck(JsCreateNamedFunction(StringToJsString(ConstructorName), NativeClass_ConstructorCallback, Self, ConstructorFunc));
  JsSetProperty(TChakraCoreContext.CurrentContext.Global, ConstructorName, ConstructorFunc, UseStrictRules);
{$ifdef SUPPORTS_CLASS_FIELDS}
  ChakraCoreCheck(JsCreateObject(Prototype));
{$else}
  AddPrototype(Self);
{$endif}
  RegisterMethods(Prototype);
  JsSetProperty(ConstructorFunc, 'prototype', Prototype, UseStrictRules);
end;

{$ifndef SUPPORTS_CLASS_FIELDS}
initialization
  InitializeProjectedClasses;

finalization
  FinalizeProjectedClasses;
{$endif}

end.
