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
{$ifdef FPC}
  Types,
{$else}
  Windows,
{$endif}
  Classes, SysUtils, Contnrs,
  Compat, ChakraCore, ChakraCommon, ChakraCoreUtils;

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
    ccroDisableFatalOnOOM,               // JsRuntimeAttributeDisableFatalOnOOM               = $00000080;
    ccroDisableExecutablePageAllocation  // JsRuntimeAttributeDisableExecutablePageAllocation = $00000100;
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
    function Process(out ResultValue: JsValueRef): Boolean; virtual; abstract;
  public
    constructor Create(AContext: TChakraCoreContext); virtual;

    property Context: TChakraCoreContext read FContext;
  end;

  TTaskMessage = class(TBaseMessage)
  private
    FArgCount: Integer;
    FArgs: PJsValueRefArray;
    FDelay: Cardinal;
    FRepeatCount: Integer;
    FTask: JsValueRef;
    FTime: Cardinal;
  protected
    function Process(out ResultValue: JsValueRef): Boolean; override;
  public
    constructor Create(AContext: TChakraCoreContext; Task, ThisArg: JsValueRef; const Args: array of JsValueRef;
      ADelay: Cardinal = 0; ARepeatCount: Integer = 1); reintroduce; virtual;
    destructor Destroy; override;

    property Delay: Cardinal read FDelay;
    property RepeatCount: Integer read FRepeatCount;
    property Task: JsValueRef read FTask;
    property Time: Cardinal read FTime;
  end;

  TPromiseStatus = (psPending, psResolved, psRejected);

  TPromiseMessage = class(TBaseMessage)
  private
    FArgs: array[0..1] of JsValueRef;
    FPromise: JsValueRef;
    FRejectTask: JsValueRef;
    FResolveTask: JsValueRef;
    FStatus: TPromiseStatus;
  protected
    function Process(out ResultValue: JsHandle): Boolean; override;
    procedure SetStatus(Value: TPromiseStatus; StatusValue: JsValueRef);
  public
    constructor Create(AContext: TChakraCoreContext; ThisArg, ResolveTask, RejectTask: JsValueRef); reintroduce; virtual;
    destructor Destroy; override;

    property Promise: JsValueRef read FPromise;
    property RejectTask: JsValueRef read FRejectTask;
    property ResolveTask: JsValueRef read FResolveTask;
    property Status: TPromiseStatus read FStatus;
  end;

  TModuleMessage = class(TBaseMessage)
  private
    FModule: TChakraModule;
  protected
    function Process(out ResultValue: JsValueRef): Boolean; override;
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
    FURL: UnicodeString;

    procedure SetURL(const Value: UnicodeString);
  public
    constructor Create(AContext: TChakraCoreContext; const AName: UnicodeString; ARefModule: JsModuleRecord);

    procedure Parse(const Source: UTF8String); overload;
    procedure Parse(const Source: UnicodeString); overload;

    property Context: TChakraCoreContext read FContext;
    property Handle: JsModuleRecord read FHandle;
    property Name: UnicodeString read FName;
    property Parsed: Boolean read FParsed;
    property Result: JsValueRef read FResult;
    property URL: UnicodeString read FURL write SetURL;
  end;

  TNativeObject = class;
  TNativeClass = class of TNativeObject;

  TLoadModuleEvent = procedure(Sender: TObject; Module: TChakraModule) of object;
  TNativeObjectCreatedEvent = procedure(Sender: TObject; NativeObject: TNativeObject) of object;

  { TChakraCoreContext }

  TChakraCoreContext = class
  private
    FGlobal: JsValueRef;
    FHandle: JsContextRef;
    FMessageQueue: TQueue;
    FModules: TStringList;
    FName: UnicodeString;
    FProjectedClasses: TList;
    FProxyTargetSymbol: JsValueRef;
    FRuntime: TChakraCoreRuntime;
    FSourceContext: NativeUInt;

    FOnActivate: TNotifyEvent;
    FOnLoadModule: TLoadModuleEvent;
    FOnNativeObjectCreated: TNativeObjectCreatedEvent;

    function AddPrototype(AClass: TNativeClass; APrototype: JsValueRef = nil): Integer;
    function FindPrototype(AClass: TNativeClass): JsValueRef;
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
    procedure DoActivate; virtual;
    procedure DoLoadModule(Module: TChakraModule); virtual;
    procedure DoNativeObjectCreated(NativeObject: TNativeObject); virtual;
    procedure DoPromiseContinuation(Task: JsValueRef); virtual;
    function HandleFetchImportedModuleCallback(referencingModule: JsModuleRecord; specifier: JsValueRef;
      out dependentModuleRecord: JsModuleRecord): JsErrorCode; virtual;
    function HandleFetchImportedModuleFromScriptCallback(dwReferencingSourceContext: JsSourceContext;
      specifier: JsValueRef; out dependentModuleRecord: JsModuleRecord): JsErrorCode; virtual;
    function HandleNotifyModuleReadyCallback(referencingModule: JsModuleRecord; exceptionVar: JsValueRef): JsErrorCode;
      virtual;
    function ModuleNeeded(const AName: UnicodeString; ARefModule: JsModuleRecord = nil): TChakraModule;
    procedure ProcessMessages;
  public
    constructor Create(ARuntime: TChakraCoreRuntime);
    destructor Destroy; override;

    procedure Activate;
    procedure AddModule(const AName: UTF8String); overload;
    procedure AddModule(const AName: UnicodeString); overload;
    function CallFunction(Func: JsValueRef; Args: PJsValueRef; ArgCount: Word): JsValueRef; overload;
    function CallFunction(const AName: UTF8String; const Args: array of JsValueRef;
      Instance: JsValueRef = nil): JsValueRef; overload;
    function CallFunction(const AName: UnicodeString; const Args: array of JsValueRef;
      Instance: JsValueRef = nil): JsValueRef; overload;
    function CallNew(const AConstructorName: UTF8String; const Args: array of JsValueRef): JsValueRef; overload;
    function CallNew(const AConstructorName: UnicodeString; const Args: array of JsValueRef): JsValueRef; overload;
    class function CurrentContext: TChakraCoreContext;
    function FindModule(const AName: UnicodeString): TChakraModule; overload;
    function FindModule(AHandle: JsModuleRecord): TChakraModule; overload;
    procedure PostMessage(AMessage: TBaseMessage);
    function RunScript(const Script, AName: UTF8String): JsValueRef; overload;
    function RunScript(const Script, AName: UnicodeString): JsValueRef; overload;

    property Data: Pointer read GetData write SetData;
    property Global: JsValueRef read GetGlobal;
    property Handle: JsContextRef read GetHandle;
    property ModuleCount: Integer read GetModuleCount;
    property ModuleNames[Index: Integer]: UnicodeString read GetModuleNames;
    property Modules[Index: Integer]: TChakraModule read GetModules;
    property Name: UnicodeString read FName;
    property ProxyTargetSymbol: JsValueRef read FProxyTargetSymbol;
    property Runtime: TChakraCoreRuntime read FRuntime;

    property OnActivate: TNotifyEvent read FOnActivate write FOnActivate;
    property OnLoadModule: TLoadModuleEvent read FOnLoadModule write FOnLoadModule;
    property OnNativeObjectCreated: TNativeObjectCreatedEvent read FOnNativeObjectCreated write FOnNativeObjectCreated;
  end;

  { TNativeArrayBuffer }

  TChakraCoreNativeArrayBuffer = class
  private
    FBuffer: Pointer;
    FBufferSize: Integer;
    FHandle: JsValueRef;
  public
    constructor Create(ABufferSize: Integer); virtual;
    destructor Destroy; override;

    property Buffer: Pointer read FBuffer;
    property BufferSize: Integer read FBufferSize;
    property Handle: JsValueRef read FHandle;
  end;

  TNativeMethod = function(Args: PJsValueRef; ArgCount: Word): JsValueRef of object;
  TNativeGetAccessorMethod = function: JsValueRef of object;
  TNativeSetAccessorMethod = procedure(Value: JsValueRef) of object;

  { TNativeObject }

  TNativeObject = class
  private
    FInstance: JsValueRef;
    FTargetInstance: JsValueRef;

    function GetContext: TChakraCoreContext;
    function GetContextHandle: JsContextRef;
    procedure Proxify;
  protected
    class function Prototype: JsValueRef;
    class procedure RegisterPrototype; virtual;
    class procedure RegisterMethod(AInstance: JsValueRef; const AName: UnicodeString; AMethod: Pointer;
      UseStrictRules: Boolean = True); virtual;
    class procedure RegisterMethods(AInstance: JsValueRef); virtual;
    class procedure RegisterProperties(AInstance: JsValueRef); virtual;
    class procedure RegisterNamedProperty(AInstance: JsValueRef; const AName: UnicodeString;
      Configurable, Enumerable: Boolean; GetAccessor, SetAccessor: Pointer); overload; virtual;
    class procedure RegisterNamedProperty(AInstance: JsValueRef; const AName: UnicodeString;
      Configurable, Enumerable, Writable: Boolean; Value: JsValueRef); overload; virtual;
  public
    constructor Create(Args: PJsValueRefArray = nil; ArgCount: Word = 0; AFinalize: Boolean = False); virtual;
    destructor Destroy; override;

    function AddRef: Integer;
    class procedure Project(const AName: UnicodeString = ''; UseStrictRules: Boolean = True);
    function Release: Integer;

    property Context: TChakraCoreContext read GetContext;
    property ContextHandle: JsContextRef read GetContextHandle;
    property Instance: JsValueRef read FInstance;
    property TargetInstance: JsValueRef read FTargetInstance;
  end;

implementation

type
  PProjectedClassInfo = ^TProjectedClassInfo;
  TProjectedClassInfo = record
    AClass: TNativeClass;
    APrototype: JsValueRef;
  end;

procedure BeforeCollectCallback(callbackState: Pointer); {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  if Assigned(callbackState) then
    TChakraCoreRuntime(callbackState).DoBeforeCollect;
end;

function ThreadServiceCallback(callback: JsBackgroundWorkItemCallback; callbackState: Pointer): bool;
  {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := False; // let ChakraCore handle this work item

  // TODO
  // Result := True;
  // CurrentRuntime.DoBackgroundWork(callback, callbackState);
end;

function FetchImportedModuleCallBack(referencingModule: JsModuleRecord; specifier: JsValueRef;
  out dependentModuleRecord: JsModuleRecord): JsErrorCode; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := TChakraCoreContext.CurrentContext.HandleFetchImportedModuleCallback(referencingModule, specifier,
    dependentModuleRecord);
end;

function FetchImportedModuleFromScriptCallBack(dwReferencingSourceContext: JsSourceContext; specifier: JsValueRef;
  out dependentModuleRecord: JsModuleRecord): JsErrorCode; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := TChakraCoreContext.CurrentContext.HandleFetchImportedModuleFromScriptCallback(dwReferencingSourceContext,
    specifier, dependentModuleRecord);
end;

function MemoryAllocationCallback(callbackState: Pointer; allocationEvent: JsMemoryEventType;
  allocationSize: size_t): bool; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
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

type
  TProxyGetArgKind = (pgaThisArg, pgaTarget, pgaProp, pgaReceiver);
  PJsProxyGetArgs = ^TJsProxyGetArgs;
  TJsProxyGetArgs = array[TProxyGetArgKind] of JsValueRef;

function Proxy_GetCallback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsProxyGetArgs; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  NativeInstance: TNativeObject absolute CallbackState;
begin
  if not Assigned(Args) or (ArgCount < 4) then
    raise Exception.Create('Invalid proxy ''get'' arguments');

  if not JsEqual(Args^[pgaTarget], NativeInstance.TargetInstance) then
    raise Exception.Create('Proxy ''get'' target not the registered target');

  if JsEqual(Args^[pgaProp], NativeInstance.Context.ProxyTargetSymbol) then
    Result := NativeInstance.TargetInstance
  else
    Result := JsGetProperty(NativeInstance.TargetInstance, Args^[pgaProp]);
end;

type
  TProxySetArgKind = (psaThisArg, psaTarget, psaProp, psaValue, psaReceiver);
  PJsProxySetArgs = ^TJsProxySetArgs;
  TJsProxySetArgs = array[TProxySetArgKind] of JsValueRef;

function Proxy_SetCallback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsProxySetArgs; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  NativeInstance: TNativeObject absolute CallbackState;
begin
  if not Assigned(Args) or (ArgCount < 5) then
    raise Exception.Create('Invalid proxy ''set'' arguments');

  if not JsEqual(Args^[psaTarget], NativeInstance.TargetInstance) then
    raise Exception.Create('Proxy ''set'' target not the registered target');

  JsSetProperty(NativeInstance.TargetInstance, Args^[psaProp], Args^[psaValue]);
  Result := JsTrueValue;
end;

type
  TProxyHasArgKind = (phaThisArg, phaTarget, phaProp);
  PJsProxyHasArgs = ^TJsProxyHasArgs;
  TJsProxyHasArgs = array[TProxyHasArgKind] of JsValueRef;

function Proxy_HasCallback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsProxyHasArgs; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  NativeInstance: TNativeObject absolute CallbackState;
begin
  if not Assigned(Args) or (ArgCount < 3) then
    raise Exception.Create('Invalid proxy ''has'' arguments');

  if not JsEqual(Args^[phaTarget], NativeInstance.TargetInstance) then
    raise Exception.Create('Proxy ''has'' target not the registered target');

  Result := BooleanToJsBoolean(JsHasProperty(Args^[phaTarget], Args^[phaProp]));
end;

procedure Native_FinalizeCallback(data: Pointer); {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  TObject(data).Free;
end;

function Native_ConstructorCallback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRef; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  NativeClass: TNativeClass absolute CallbackState;
  NativeInstance: TNativeObject;
begin
  Result := JsUndefinedValue;
  try
    if not IsConstructCall then
      raise Exception.Create('Constructor called as a method');

    Inc(Args);
    Dec(ArgCount);

    NativeInstance := NativeClass.Create(Pointer(Args), ArgCount, True);
    Result := NativeInstance.Instance;
  except on E: Exception do
    JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function Native_MethodCallback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRef;
  ArgCount: Word; CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  NativeMethod: TNativeMethod;
begin
  Result := JsUndefinedValue;
  try
    if IsConstructCall then
      raise Exception.Create('Method called as a constructor');

    if not Assigned(Args) or (ArgCount = 0) then
      raise Exception.Create('Invalid arguments');

    if (JsGetValueType(Args^) <> JsObject) then
      raise Exception.Create('thisarg not an object');

    TMethod(NativeMethod).Code := CallbackState;
    TMethod(NativeMethod).Data := JsGetExternalData(Args^);

    if Args^ <> TNativeObject(TMethod(NativeMethod).Data).Instance then
      raise Exception.Create('thisarg not the registered instance');

    Inc(Args);
    Dec(ArgCount);

    Result := NativeMethod(Args, ArgCount);
  except
    on E: Exception do
      JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function Native_PropGetCallback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRef; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  NativeMethod: TNativeGetAccessorMethod;
begin
  Result := JsUndefinedValue;
  try
    if IsConstructCall then
      raise Exception.Create('Property get accessor called as a constructor');

    if not Assigned(Args) or (ArgCount <> 1) then // thisarg
      raise Exception.Create('Invalid arguments');

    TMethod(NativeMethod).Code := CallbackState;
    TMethod(NativeMethod).Data := JsGetExternalData(Args^);

    if Args^ <> TNativeObject(TMethod(NativeMethod).Data).TargetInstance then
      raise Exception.Create('thisarg not the registered instance');

    Result := NativeMethod;
  except
    on E: Exception do
      JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function Native_PropSetCallback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  NativeMethod: TNativeSetAccessorMethod;
begin
  Result := JsUndefinedValue;
  try
    if IsConstructCall then
      raise Exception.Create('Property set accessor called as a constructor');

    if not Assigned(Args) or (ArgCount <> 2) then // thisarg, value
      raise Exception.Create('Invalid arguments');

    TMethod(NativeMethod).Code := CallbackState;
    TMethod(NativeMethod).Data := JsGetExternalData(Args^[0]);

    if Args^[0] <> TNativeObject(TMethod(NativeMethod).Data).TargetInstance then
      raise Exception.Create('thisarg not the registered instance');

    NativeMethod(Args^[1]);
  except
    on E: Exception do
      JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
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
  if ccroDisableExecutablePageAllocation in Value then
    Result := Result or JsRuntimeAttributeDisableExecutablePageAllocation;
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

function TTaskMessage.Process(out ResultValue: JsValueRef): Boolean;
var
  Ticks: Cardinal;
begin
  ResultValue := JsUndefinedValue;
  Ticks := GetTickCount;
  Result := Ticks >= FTime + FDelay;
  if Result then
  begin
    ResultValue := JsCallFunction(FTask, @FArgs^[0], FArgCount + 1);

    if FRepeatCount > 0 then
      Dec(FRepeatCount);
    if FRepeatCount = 0 then
      Exit;

    Result := False;
    ResultValue := JsUndefinedValue;
    FTime := GetTickCount;
  end;
end;

{ TCallbackMessage public }

constructor TTaskMessage.Create(AContext: TChakraCoreContext; Task, ThisArg: JsValueRef;
  const Args: array of JsValueRef; ADelay: Cardinal; ARepeatCount: Integer);
var
  I: Integer;
begin
  inherited Create(AContext);
  FTask := Task;
  ChakraCoreCheck(JsAddRef(FTask, nil));

  FArgCount := Length(Args);
  FArgs := AllocMem((FArgCount + 1) * SizeOf(PJsValueRef));
  if Assigned(ThisArg) then
    FArgs^[0] := ThisArg
  else
    FArgs^[0] := Context.Global;
  ChakraCoreCheck(JsAddRef(FArgs^[0], nil));

  for I := 1 to FArgCount do
  begin
    FArgs^[I] := Args[I - 1];
    ChakraCoreCheck(JsAddRef(FArgs^[I], nil));
  end;

  FDelay := ADelay;
  FRepeatCount := ARepeatCount;
  FTime := GetTickCount;
end;

destructor TTaskMessage.Destroy;
var
  I: Integer;
begin
  if Assigned(FArgs) then
  begin
    for I := 0 to FArgCount do
      if Assigned(FArgs^[I]) then
        ChakraCoreCheck(JsRelease(FArgs^[I], nil));
    FreeMem(FArgs);
  end;
  FArgs := nil;
  FArgCount := 0;
  if Assigned(FTask) then
    ChakraCoreCheck(JsRelease(FTask, nil));
  FTask := nil;
  inherited Destroy;
end;

{ TPromiseMessage protected }

function TPromiseMessage.Process(out ResultValue: JsHandle): Boolean;
begin
  Result := False;
  ResultValue := JsUndefinedValue;
  case FStatus of
    psPending:
      Exit;
    psResolved:
      ResultValue := JsCallFunction(FResolveTask, @FArgs[0], 2);
    psRejected:
      ResultValue := JsCallFunction(FRejectTask, @Fargs[0], 2);
  end;
  Result := True;
end;

procedure TPromiseMessage.SetStatus(Value: TPromiseStatus; StatusValue: JsValueRef);
begin
  FArgs[1] := StatusValue;
  FStatus := Value;
end;

{ TPromiseMessage public }

constructor TPromiseMessage.Create(AContext: TChakraCoreContext; ThisArg, ResolveTask, RejectTask: JsValueRef);
begin
  inherited Create(AContext);
  FArgs[0] := ThisArg;
  ChakraCoreCheck(JsAddRef(FArgs[0], nil));
  FArgs[1] := nil;
  FResolveTask := ResolveTask;
  ChakraCoreCheck(JsAddRef(FResolveTask, nil));
  FRejectTask := RejectTask;
  ChakraCoreCheck(JsAddRef(FRejectTask, nil));
end;

destructor TPromiseMessage.Destroy;
begin
  if Assigned(FRejectTask) then
    ChakraCoreCheck(JsRelease(FRejectTask, nil));
  FRejectTask := nil;
  if Assigned(FResolveTask) then
    ChakraCoreCheck(JsRelease(FResolveTask, nil));
  FResolveTask := nil;
  if Assigned(FArgs[0]) then
    ChakraCoreCheck(JsRelease(FArgs[0], nil));
  FArgs[0] := nil;
  if Assigned(FArgs[1]) then
    ChakraCoreCheck(JsRelease(FArgs[1], nil));
  FArgs[1] := nil;
  inherited Destroy;
end;

{ TModuleMessage protected }

function TModuleMessage.Process(out ResultValue: JsValueRef): Boolean;
begin
  ChakraCoreCheck(JsModuleEvaluation(FModule.Handle, FModule.FResult));
  Result := True;
  ResultValue := FModule.FResult;
end;

{ TModuleMessage public }

constructor TModuleMessage.Create(AContext: TChakraCoreContext; AModule: TChakraModule);
begin
  inherited Create(AContext);
  FModule := AModule;
end;

{ TChakraModule public }

constructor TChakraModule.Create(AContext: TChakraCoreContext; const AName: UnicodeString; ARefModule: JsModuleRecord);
var
  Specifier: JsValueRef;
begin
  inherited Create;
  FContext := AContext;
  FName := AName;
  FURL := '';

  FResult := JsUndefinedValue;
  Specifier := JS_INVALID_REFERENCE;
  if AName <> '' then
    Specifier := StringToJsString(AName);

  ChakraCoreCheck(JsInitializeModuleRecord(ARefModule, Specifier, FHandle));
  ChakraCoreCheck(JsSetModuleHostInfo(FHandle, JsModuleHostInfo_FetchImportedModuleCallback, @FetchImportedModuleCallback));
  ChakraCoreCheck(JsSetModuleHostInfo(FHandle, JsModuleHostInfo_FetchImportedModuleFromScriptCallback, @FetchImportedModuleFromScriptCallback));
  ChakraCoreCheck(JsSetModuleHostInfo(FHandle, JsModuleHostInfo_NotifyModuleReadyCallback, @NotifyModuleReadyCallback));
  ChakraCoreCheck(JsSetModuleHostInfo(FHandle, JsModuleHostInfo_HostDefined, Specifier));
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

procedure TChakraModule.SetURL(const Value: UnicodeString);
var
  Specifier: JsValueRef;
begin
  if Value <> FURL then
  begin
    Specifier := JS_INVALID_REFERENCE;
    if Value <> '' then
      Specifier := StringToJsString(Value);

    ChakraCoreCheck(JsSetModuleHostInfo(FHandle, JsModuleHostInfo_Url, Specifier));

    FURL := Value;
  end;
end;

procedure PromiseContinuation(task: JsValueRef; callbackState: Pointer); {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  if Assigned(callbackState) then
    TChakraCoreContext(callbackState).DoPromiseContinuation(task);
end;

{ TChakraCoreContext private }

function TChakraCoreContext.AddPrototype(AClass: TNativeClass; APrototype: JsValueRef): Integer;
var
  Info: PProjectedClassInfo;
begin
  if not Assigned(APrototype) then
    APrototype := JsCreateObject;

  GetMem(Info, SizeOf(TProjectedClassInfo));
  try
    Info^.AClass := AClass;
    Info^.APrototype := APrototype;

    Result := FProjectedClasses.Add(Info);
  except
    FreeMem(Info);
    raise;
  end;
end;

function TChakraCoreContext.FindPrototype(AClass: TNativeClass): JsValueRef;
var
  I: Integer;
begin
  Result := nil;

  for I := 0 to FProjectedClasses.Count - 1 do
    if PProjectedClassInfo(FProjectedClasses[I])^.AClass = AClass then
    begin
      Result := PProjectedClassInfo(FProjectedClasses[I])^.APrototype;
      Break;
    end;
end;

function TChakraCoreContext.GetData: Pointer;
begin
  ChakraCoreCheck(JsGetContextData(FHandle, Result));
end;

function TChakraCoreContext.GetGlobal: JsValueRef;
begin
  if FGlobal = JS_INVALID_REFERENCE then
    FGlobal := JsGlobal;
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

procedure TChakraCoreContext.DoActivate;
begin
  if Assigned(FOnActivate) then
    FOnActivate(Self);
end;

procedure TChakraCoreContext.DoLoadModule(Module: TChakraModule);
begin
  if Assigned(FOnLoadModule) then
    FOnLoadModule(Self, Module);
end;

procedure TChakraCoreContext.DoNativeObjectCreated(NativeObject: TNativeObject);
begin
  if Assigned(FOnNativeObjectCreated) then
    FOnNativeObjectCreated(Self, NativeObject);
end;

procedure TChakraCoreContext.DoPromiseContinuation(Task: JsValueRef);
var
  AMessage: TTaskMessage;
begin
  AMessage := TTaskMessage.Create(Self, Task, nil, []);
  try
    PostMessage(AMessage);
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
  ResultValue: JsValueRef;
begin
  while FMessageQueue.Count > 0 do
  begin
    AMessage := FMessageQueue.Pop;
    if AMessage.Process(ResultValue) then
      AMessage.Free
    else
      FMessageQueue.Push(AMessage);
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
  FProjectedClasses := TList.Create;
end;

destructor TChakraCoreContext.Destroy;
var
  I: Integer;
begin
  for I := FProjectedClasses.Count - 1 downto 0 do
    FreeMem(FProjectedClasses[I]);
  FreeAndNil(FProjectedClasses);
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
  FProxyTargetSymbol := JsCreateSymbol('__proxy_target__');
  ChakraCoreCheck(JsAddRef(FProxyTargetSymbol, nil));
  DoActivate;
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

function TChakraCoreContext.CallFunction(Func: JsValueRef; Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsCallFunction(Func, Args, ArgCount);
  ProcessMessages;
end;

function TChakraCoreContext.CallFunction(const AName: UTF8String; const Args: array of JsValueRef;
  Instance: JsValueRef): JsValueRef;
begin
  Result := JsCallFunction(AName, Args, Instance);
  ProcessMessages;
end;

function TChakraCoreContext.CallFunction(const AName: UnicodeString; const Args: array of JsValueRef;
  Instance: JsValueRef): JsValueRef;
begin
  Result := CallFunction(UTF8Encode(AName), Args, Instance);
end;

function TChakraCoreContext.CallNew(const AConstructorName: UTF8String; const Args: array of JsValueRef): JsValueRef;
begin
  Result := JsNew(UTF8Decode(AConstructorName), Args);
  ProcessMessages;
end;

function TChakraCoreContext.CallNew(const AConstructorName: UnicodeString; const Args: array of JsValueRef): JsValueRef;
begin
  Result := CallNew(UTF8Encode(AConstructorName), Args);
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

procedure TChakraCoreContext.PostMessage(AMessage: TBaseMessage);
begin
  FMessageQueue.Push(AMessage);
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

{ TChakraCoreNativeArrayBuffer public }

constructor TChakraCoreNativeArrayBuffer.Create(ABufferSize: Integer);
begin
  inherited Create;
  FBuffer := AllocMem(ABufferSize);
  FBufferSize := ABufferSize;
  ChakraCoreCheck(JsCreateExternalArrayBuffer(FBuffer, FBufferSize, Native_FinalizeCallback, Self, FHandle));
end;

destructor TChakraCoreNativeArrayBuffer.Destroy;
begin
  if Assigned(FBuffer) then
    FreeMem(FBuffer);
  inherited Destroy;
end;

{ TChakraCoreNativeObject private }

function TNativeObject.GetContext: TChakraCoreContext;
var
  P: Pointer absolute Result;
begin
  ChakraCoreCheck(JsGetContextData(ContextHandle, P));
end;

function TNativeObject.GetContextHandle: JsContextRef;
begin
  ChakraCoreCheck(JsGetContextOfObject(FInstance, Result));
end;

procedure TNativeObject.Proxify;
var
  Handler: JsValueRef;
begin
  JsSetProperty(FInstance, Context.ProxyTargetSymbol, FInstance);
  Handler := JsCreateObject;
  JsSetCallback(Handler, 'get', @Proxy_GetCallback, Self);
  JsSetCallback(Handler, 'set', @Proxy_SetCallback, Self);
  JsSetCallback(Handler, 'has', @Proxy_HasCallback, Self);
  FTargetInstance := FInstance;
  FInstance := JsNew('Proxy', [JsUndefinedValue, FInstance, Handler]);
end;

class procedure TNativeObject.RegisterPrototype;
begin
  TChakraCoreContext.CurrentContext.AddPrototype(Self);
  RegisterMethods(Prototype);
  RegisterProperties(Prototype);
end;

{ TChakraCoreNativeObject protected }

class function TNativeObject.Prototype: JsValueRef;
begin
  Result := TChakraCoreContext.CurrentContext.FindPrototype(Self);
end;

class procedure TNativeObject.RegisterMethod(AInstance: JsValueRef; const AName: UnicodeString;
  AMethod: Pointer; UseStrictRules: Boolean);
begin
  JsSetCallback(AInstance, AName, Native_MethodCallback, AMethod, UseStrictRules);
end;

class procedure TNativeObject.RegisterMethods(AInstance: JsValueRef);
begin
  // do nothing
end;

class procedure TNativeObject.RegisterProperties(AInstance: JsValueRef);
begin
  // do nothing
end;

class procedure TNativeObject.RegisterNamedProperty(AInstance: JsValueRef; const AName: UnicodeString;
  Configurable, Enumerable: Boolean; GetAccessor, SetAccessor: Pointer);
var
  Descriptor: JsValueRef;
  PropName: UTF8String;
  PropId: JsPropertyIdRef;
  B: ByteBool;
begin
  Descriptor := JsCreateObject;
  JsSetProperty(Descriptor, 'configurable', BooleanToJsBoolean(Configurable), True);
  JsSetProperty(Descriptor, 'enumerable', BooleanToJsBoolean(Enumerable), True);
  if Assigned(GetAccessor) then
    JsSetCallback(Descriptor, 'get', Native_PropGetCallback, GetAccessor, True);
  if Assigned(SetAccessor) then
    JsSetCallback(Descriptor, 'set', @Native_PropSetCallback, SetAccessor, True);
  PropName := UTF8Encode(AName);
  ChakraCoreCheck(JsCreatePropertyId(PAnsiChar(PropName), Length(PropName), PropId));
  ChakraCoreCheck(JsDefineProperty(AInstance, PropId, Descriptor, B));
end;

class procedure TNativeObject.RegisterNamedProperty(AInstance: JsValueRef; const AName: UnicodeString;
  Configurable, Enumerable, Writable: Boolean; Value: JsValueRef);
var
  Descriptor: JsValueRef;
  PropName: UTF8String;
  PropId: JsPropertyIdRef;
  B: ByteBool;
begin
  Descriptor := JsCreateObject;
  JsSetProperty(Descriptor, 'configurable', BooleanToJsBoolean(Configurable), True);
  JsSetProperty(Descriptor, 'enumerable', BooleanToJsBoolean(Enumerable), True);
  JsSetProperty(Descriptor, 'writable', BooleanToJsBoolean(Writable));
  JsSetProperty(Descriptor, 'value', Value, True);
  PropName := UTF8Encode(AName);
  ChakraCoreCheck(JsCreatePropertyId(PAnsiChar(PropName), Length(PropName), PropId));
  ChakraCoreCheck(JsDefineProperty(AInstance, PropId, Descriptor, B));
end;

{ TChakraCoreNativeObject public }

constructor TNativeObject.Create(Args: PJsValueRefArray; ArgCount: Word; AFinalize: Boolean);
const
  Finalizers: array[Boolean] of JsFinalizeCallback = (nil, Native_FinalizeCallback);
var
  APrototype: JsValueRef;
begin
  inherited Create;
  FInstance := nil;
  ChakraCoreCheck(JsCreateExternalObject(Self, Finalizers[AFinalize], FInstance));
  JsSetExternalData(FInstance, Self);
  APrototype := Prototype;
  if Assigned(APrototype) then
    ChakraCoreCheck(JsSetPrototype(FInstance, Prototype))
  else
  begin
    RegisterMethods(FInstance);
    RegisterProperties(FInstance);
  end;
  Proxify;
  Context.DoNativeObjectCreated(Self);
end;

destructor TNativeObject.Destroy;
begin
  // TODO detect context already destroyed
  if Assigned(FInstance) then
    ChakraCommon.JsSetExternalData(FInstance, nil);
  inherited;
end;

function TNativeObject.AddRef: Integer;
begin
  ChakraCoreCheck(JsAddRef(FTargetInstance, @Result));
end;

class procedure TNativeObject.Project(const AName: UnicodeString; UseStrictRules: Boolean);
var
  ConstructorName: UnicodeString;
  ConstructorFunc: JsValueRef;
begin
  ConstructorName := AName;
  if ConstructorName = '' then
    ConstructorName := UnicodeString(ClassName);
  ChakraCoreCheck(JsCreateNamedFunction(StringToJsString(ConstructorName), Native_ConstructorCallback, Self,
    ConstructorFunc));
  JsSetProperty(JsGlobal, ConstructorName, ConstructorFunc, UseStrictRules);
  RegisterPrototype;
  ChakraCoreCheck(JsSetPrototype(ConstructorFunc, Prototype));
end;

function TNativeObject.Release: Integer;
begin
  ChakraCoreCheck(JsRelease(FTargetInstance, @Result));
end;

end.
