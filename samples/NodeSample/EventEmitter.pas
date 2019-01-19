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

unit EventEmitter;

{$include common.inc}

interface

uses
  Classes, SysUtils,
  Compat, ChakraCore, ChakraCommon, ChakraCoreUtils, ChakraCoreClasses;

const
  DefaultMaxListeners = 10;

type

  TEventEmitter = class;

  { TEvent }

  TEvent = class
  private
    FName: JsValueRef;
    FListeners: TList;
    FOnceList: TList;
    FOwner: TEventEmitter;

    function GetListenerCount: Integer;
    function GetListeners(Index: Integer): JsValueRef;
  public
    constructor Create(AOwner: TEventEmitter; AName: JsValueRef);
    destructor Destroy; override;

    function AddListener(AListener: JsValueRef; AOnce: Boolean = False): Integer;
    procedure Emit(Args: PJsValueRef; ArgCount: Word); overload;
    procedure Emit(const Args: array of JsValueRef); overload;
    procedure PrependListener(AListener: JsValueRef; AOnce: Boolean = False);
    function RemoveListener(AListener: JsValueRef): Integer;
    procedure RemoveListeners;

    property Name: JsValueRef read FName;
    property ListenerCount: Integer read GetListenerCount;
    property Listeners[Index: Integer]: JsValueRef read GetListeners;
    property Owner: TEventEmitter read FOwner;
  end;

  { TEventEmitter }

  TEventEmitter = class(TNativeObject)
  private
    FEvents: TList;
    FMaxListeners: Integer;

    function GetEventCount: Integer;
    function GetEvents(Index: Integer): TEvent;
    function GetMaxListeners: Integer;
    procedure SetMaxListeners(AValue: Integer);
  protected
    class function InitializePrototype(AConstructor: JsValueRef): JsValueRef; override;
    class procedure RegisterMethods(AInstance: JsValueRef); override;

    function _AddListener(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _Emit(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function _EventNames(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _GetMaxListeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _ListenerCount(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _Listeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _Off(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _On(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _Once(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _PrependListener(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _PrependOnceListener(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _RemoveAllListeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _RemoveListener(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _SetMaxListeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
    function _RawListeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
  public
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); overload; override;
    destructor Destroy; override;

    procedure AddListener(Name, Listener: JsValueRef; Once: Boolean = False);
    function FindEvent(Name: JsValueRef): TEvent;
    procedure PrependListener(Name, Listener: JsValueRef; Once: Boolean = False);
    procedure RemoveListener(Name, Listener: JsValueRef);

    property EventCount: Integer read GetEventCount;
    property Events[Index: Integer]: TEvent read GetEvents;
    property MaxListeners: Integer read GetMaxListeners write SetMaxListeners;
  end;

implementation

// TODO move to ChakraCoreUtils

type
  JsValueTypes = set of JsValueType;

const
  JsValueTypeStrings: array[JsValueType] of UnicodeString = (
    'undefined',
    'null',
    'number',
    'string',
    'boolean',
    'object',
    'function',
    'error',
    'array',
    'symbol',
    'ArrayBuffer',
    'TypedArray',
    'DataView'
);

function JsValueTypesStr(ValueTypes: JsValueTypes): UnicodeString;
var
  ValueType: JsValueType;
begin
  Result := '';
  for ValueType := Low(JsValueType) to High(JsValueType) do
    if ValueType in ValueTypes then
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + JsValueTypeStrings[ValueType];
    end;
end;

procedure CheckArgCount(Expected, Actual: Word);
begin
  if Expected <> Actual then
    raise Exception.CreateFmt('Invalid number of arguments: %d (expected %d)', [Actual, Expected]);
end;

procedure CheckMinArgCount(Expected, Actual: Word);
begin
  if Expected > Actual then
    raise Exception.CreateFmt('Invalid number of arguments: %d (expected at least %d)', [Actual, Expected]);
end;

procedure CheckArgValueType(Expected: JsValueType; Arg: JsValueRef); overload;
var
  ArgValueType: JsValueType;
begin
  ArgValueType := JsGetValueType(Arg);
  if Expected <> ArgValueType then
    raise Exception.CreateFmt('Invalid argument type %s (expected %s)',
      [JsValueTypeStrings[ArgValueType], JsValueTypeStrings[Expected]]);
end;

procedure CheckArgValueType(Expected: JsValueTypes; Arg: JsValueRef); overload;
var
  ArgValueType: JsValueType;
begin
  ArgValueType := JsGetValueType(Arg);
  if not (ArgValueType in Expected) then
    raise Exception.CreateFmt('Invalid argument type %s (expected %s)', [JsValueTypesStr(Expected)]);
end;

{ TEvent private }

function TEvent.GetListenerCount: Integer;
begin
  Result := FListeners.Count;
end;

function TEvent.GetListeners(Index: Integer): JsValueRef;
begin
  Result := FListeners[Index];
end;

{ TEvent public }

constructor TEvent.Create(AOwner: TEventEmitter; AName: JsValueRef);
begin
  inherited Create;
  FOwner := AOwner;
  FName := AName;
  FListeners := TList.Create;
  FOnceList := TList.Create;
  if Assigned(FOwner) then
    FOwner.FEvents.Add(Self);
end;

destructor TEvent.Destroy;
begin
  if Assigned(FOwner) then
    FOwner.FEvents.Remove(Self);
  FListeners.Free;
  FOnceList.Free;
  inherited Destroy;
end;

function TEvent.AddListener(AListener: JsValueRef; AOnce: Boolean): Integer;
begin
  Result := FListeners.Add(AListener);
  if AOnce and (FOnceList.IndexOf(AListener) = -1) then
    FOnceList.Add(AListener);
end;

procedure TEvent.Emit(Args: PJsValueRef; ArgCount: Word);
var
  NewArgs: array of JsValueRef;
  I, J: Integer;
begin
  SetLength(NewArgs, ArgCount + 1);
  NewArgs[0] := FOwner.Instance;
  if ArgCount > 0 then
    Move(Args^, NewArgs[1], ArgCount * SizeOf(JsValueRef));

  for I := 0 to FListeners.Count - 1 do
    JsCallFunction(FListeners[I], @NewArgs[0], ArgCount + 1);

  for I := FListeners.Count - 1 downto 0 do
  begin
    J := FOnceList.IndexOf(FListeners[I]);
    if J <> -1 then
    begin
      FListeners.Delete(I);
      FOnceList.Delete(J);
    end;
  end;
end;

procedure TEvent.Emit(const Args: array of JsValueRef);
var
  PArg: PJsValueRef;
  Len: Integer;
begin
  PArg := nil;
  Len := Length(Args);
  if Len > 0 then
    PArg := @Args[0];
  Emit(PArg, Len);
end;

procedure TEvent.PrependListener(AListener: JsValueRef; AOnce: Boolean);
begin
  FListeners.Insert(0, AListener);
  if AOnce and (FOnceList.IndexOf(AListener) = -1) then
    FOnceList.Add(AListener);
end;

function TEvent.RemoveListener(AListener: JsValueRef): Integer;
begin
  Result := FListeners.Remove(AListener);
end;

procedure TEvent.RemoveListeners;
begin
  FListeners.Clear;
end;

{ TEventEmitter private }

function TEventEmitter.GetEventCount: Integer;
begin
  Result := FEvents.Count;
end;

function TEventEmitter.GetEvents(Index: Integer): TEvent;
begin
  Result := TEvent(FEvents[Index]);
end;

function TEventEmitter.GetMaxListeners: Integer;
begin
  Result := FMaxListeners;
  if Result = -1 then
    Result := JsNumberToInt(JsValueAsJsNumber(JsGetProperty(Instance, 'defaultMaxListeners')));
end;

procedure TEventEmitter.SetMaxListeners(AValue: Integer);
begin
  if AValue <> FMaxListeners then
  begin
    if AValue < 0 then
      FMaxListeners := -1
    else
      FMaxListeners := AValue;
  end;
end;

{ TEventEmitter protected }

class function TEventEmitter.InitializePrototype(AConstructor: JsValueRef): JsValueRef;
begin
  Result := inherited InitializePrototype(AConstructor);
  JsSetProperty(Result, 'defaultMaxListeners', IntToJsNumber(DefaultMaxListeners));
  RegisterClassMethod(AConstructor, 'listenerCount', @TEventEmitter._ListenerCount);
end;

class procedure TEventEmitter.RegisterMethods(AInstance: JsValueRef);
begin
  RegisterMethod(AInstance, 'addListener',         @TEventEmitter._AddListener);
  RegisterMethod(AInstance, 'emit',                @TEventEmitter._Emit);
  RegisterMethod(AInstance, 'eventNames',          @TEventEmitter._EventNames);
  RegisterMethod(AInstance, 'getMaxListeners',     @TEventEmitter._GetMaxListeners);
  RegisterMethod(AInstance, 'listeners',           @TEventEmitter._Listeners);
  RegisterMethod(AInstance, 'off',                 @TEventEmitter._Off);
  RegisterMethod(AInstance, 'on',                  @TEventEmitter._On);
  RegisterMethod(AInstance, 'once',                @TEventEmitter._Once);
  RegisterMethod(AInstance, 'prependListener',     @TEventEmitter._PrependListener);
  RegisterMethod(AInstance, 'prependOnceListener', @TEventEmitter._PrependOnceListener);
  RegisterMethod(AInstance, 'removeAllListeners',  @TEventEmitter._RemoveAllListeners);
  RegisterMethod(AInstance, 'removeListener',      @TEventEmitter._RemoveListener);
  RegisterMethod(AInstance, 'setMaxListeners',     @TEventEmitter._SetMaxListeners);
  RegisterMethod(AInstance, 'rawListeners',        @TEventEmitter._RawListeners);
end;

function TEventEmitter._AddListener(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := _On(Args, ArgCount);
end;

function TEventEmitter._Emit(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  Event: TEvent;
begin
  Result := JsUndefinedValue;
  try
    CheckMinArgCount(1, ArgCount);
    CheckArgValueType([JsSymbol, JsString], Args^);

    Event := FindEvent(Args^);
    if not Assigned(Event) then
      raise EListError.CreateFmt('Event %s not found', [JsStringToUnicodeString(JsValueAsJsString(Args^))]);

    Inc(Args);
    Dec(ArgCount);

    Event.Emit(Args, ArgCount);
    Result := Instance;
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._EventNames(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
var
  I: Integer;
begin
  Result := JsUndefinedValue;
  try
    Result := JsCreateArray(EventCount);
    for I := 0 to EventCount - 1 do
      JsSetIndexedProperty(Result, IntToJsNumber(I), Events[I].Name);
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._GetMaxListeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  try
    Result := IntToJsNumber(GetMaxListeners);
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._ListenerCount(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
var
  Emitter: TEventEmitter;
  Event: TEvent;
begin
  Result := JsUndefinedValue;
  try
    CheckArgCount(2, ArgCount);
    CheckArgValueType([JsObject], Args^[0]);
    CheckArgValueType([JsSymbol, JsString], Args^[1]);

    Emitter := TEventEmitter(JsGetExternalData(Args^[0]));
    Event := Emitter.FindEvent(Args^[1]);
    if not Assigned(Event) then
      raise EListError.CreateFmt('Event ''%s'' not found for %s', [JsStringToUnicodeString(JsValueAsJsString(Args^[1])),
        Emitter.ClassName]);

    Result := IntToJsNumber(Event.ListenerCount);
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._Listeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
var
  Event: TEvent;
  I: Integer;
begin
  Result := JsUndefinedValue;
  try
    CheckArgCount(1, ArgCount);
    CheckArgValueType([JsSymbol, JsString], Args^[0]);
    Event := FindEvent(Args^[0]);
    if not Assigned(Event) then
      raise EListError.CreateFmt('Event %s not found', [JsStringToUnicodeString(JsValueAsJsString(Args^[0]))]);

    Result := JsCreateArray(Event.ListenerCount);
    for I := 0 to Event.ListenerCount - 1 do
      JsSetIndexedProperty(Result, IntToJsNumber(I), Event.Listeners[I]);
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._Off(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  try
    CheckArgCount(2, ArgCount);
    CheckArgValueType([JsSymbol, JsString], Args^[0]);
    CheckArgValueType(JsFunction, Args^[1]);
    RemoveListener(Args^[0], Args^[1]);
    Result := Instance;
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._On(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  try
    CheckArgCount(2, ArgCount);
    CheckArgValueType([JsSymbol, JsString], Args^[0]);
    CheckArgValueType(JsFunction, Args^[1]);
    AddListener(Args^[0], Args^[1]);
    Result := Instance;
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._Once(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  try
    CheckArgCount(2, ArgCount);
    CheckArgValueType([JsSymbol, JsString], Args^[0]);
    CheckArgValueType(JsFunction, Args^[1]);
    AddListener(Args^[0], Args^[1], True);
    Result := Instance;
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._PrependListener(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  try
    CheckArgCount(2, ArgCount);
    CheckArgValueType([JsSymbol, JsString], Args^[0]);
    CheckArgValueType(JsFunction, Args^[1]);
    PrependListener(Args^[0], Args^[1]);
    Result := Instance;
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._PrependOnceListener(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  try
    CheckArgCount(2, ArgCount);
    CheckArgValueType([JsSymbol, JsString], Args^[0]);
    CheckArgValueType(JsFunction, Args^[1]);
    PrependListener(Args^[0], Args^[1], True);
    Result := Instance;
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._RemoveAllListeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
var
  I: Integer;
  Event: TEvent;
begin
  Result := JsUndefinedValue;
  try
    if ArgCount = 0 then
    begin
      for I := 0 to EventCount - 1 do
        Events[I].RemoveListeners;
    end
    else
    begin
      CheckArgValueType([JsSymbol, JsString], Args^[0]);
      Event := FindEvent(Args^[0]);
      if not Assigned(Event) then
        raise EListError.CreateFmt('Event %s not found', [JsStringToUnicodeString(JsValueAsJsString(Args^[0]))]);
      Event.RemoveListeners;
    end;

    Result := Instance;
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._RemoveListener(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := _Off(Args, ArgCount);
end;

function TEventEmitter._SetMaxListeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  try
    CheckArgCount(1, ArgCount);
    CheckArgValueType(JsNumber, Args^[0]);
    MaxListeners := JsNumberToInt(Args^[0]);
    Result := Instance;
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TEventEmitter._RawListeners(Args: PJsValueRefArray; ArgCount: Word): JsValueRef;
begin
  Result := _Listeners(Args, ArgCount);
end;

{ TEventEmitter public }

constructor TEventEmitter.Create(Args: PJsValueRef; ArgCount: Word; AFinalize: Boolean);
begin
  inherited Create(Args, ArgCount, AFinalize);
  FEvents := TList.Create;
  FMaxListeners := -1;
  TEvent.Create(Self, StringToJsString('newListener'));
  TEvent.Create(Self, StringToJsString('removeListener'));
end;

destructor TEventEmitter.Destroy;
var
  I: Integer;
begin
  for I := FEvents.Count - 1 downto 0 do
    TEvent(FEvents[I]).Free;
  FEvents.Free;
  inherited Destroy;
end;

procedure TEventEmitter.AddListener(Name, Listener: JsValueRef; Once: Boolean);
var
  Event: TEvent;
begin
  Event := FindEvent(Name);
  if not Assigned(Event) then
    Event := TEvent.Create(Self, Name);
  Event.AddListener(Listener, Once);

  Event := FindEvent(StringToJsString('newListener'));
  Event.Emit([Name, Listener]);
end;

function TEventEmitter.FindEvent(Name: JsValueRef): TEvent;
var
  I: Integer;
begin
  Result := nil;

  for I := 0 to EventCount - 1 do
    if JsEqual(Name, Events[I].Name) then
    begin
      Result := Events[I];
      Break;
    end;
end;

procedure TEventEmitter.PrependListener(Name, Listener: JsValueRef; Once: Boolean);
var
  Event: TEvent;
begin
  Event := FindEvent(Name);
  if not Assigned(Event) then
    Event := TEvent.Create(Self, Name);
  Event.PrependListener(Listener, Once);

  Event := FindEvent(StringToJsString('newListener'));
  Event.Emit([Name, Listener]);
end;

procedure TEventEmitter.RemoveListener(Name, Listener: JsValueRef);
var
  Event: TEvent;
begin
  Event := FindEvent(Name);
  if Assigned(Event) then
    Event.RemoveListener(Listener);

  Event := FindEvent(StringToJsString('removeListener'));
  Event.Emit([Name, Listener]);
end;

end.
