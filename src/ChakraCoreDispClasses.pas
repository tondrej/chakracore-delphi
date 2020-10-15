(*

MIT License

Copyright (c) 2020 Ondrej Kelle

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

unit ChakraCoreDispClasses;

{$include common.inc}

interface

uses
  Windows, ActiveX, ComObj, Classes, SysUtils,
  ChakraCommon, ChakraCore, ChakraCoreClasses, ChakraCoreUtils;

type
  TDispProxy = class(TProxy)
  private
    FDisp: IDispatch;
    FMethods: JsValueRefArray;

    function DispCall(const MethodName: WideString; const Args: array of Variant): Variant;
    function DispGetMemberID(const PropName: WideString; out PropID: Integer): Boolean;
    function DispGetMethod(const MethodName: WideString; out Method: JsValueRef): Boolean;
    function DispPropGet(const PropName: WideString; out Value: Variant): Boolean;
    function DispPropPut(const PropName: WideString; const Value: Variant; ByRef: Boolean = False): Boolean;
  protected
    function DoGet(Prop: JsValueRef): JsValueRef; override;
    function DoHas(Prop: JsValueRef): Boolean; override;
    function DoOwnKeys: JsValueRef; override;
    function DoSet(Prop, Value: JsValueRef): Boolean; override;
  public
    constructor Create(const ADisp: IDispatch); reintroduce; virtual;
    destructor Destroy; override;

    property Disp: IDispatch read FDisp;
  end;

function DispToJsValue(const Disp: IDispatch): JsValueRef;

implementation

uses
  Variants, VarUtils,
  ChakraCoreVarUtils;

const
  LOCALE_NEUTRAL = 0;

function Disp_MethodCallback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRef; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  Proxy: TDispProxy absolute CallbackState;
  VArgs: array of Variant;
  I: Integer;
begin
  Result := JsUndefinedValue;
  try
    if not Assigned(CallbackState) then
      raise Exception.Create('Dispatch method callback: state not assigned');

    if IsConstructCall then
      raise Exception.Create('Dispatch method callback: called as a constructor');

    if not Assigned(Args) then
      raise Exception.Create('Dispatch method callback: arguments not assigned');

    if ArgCount < 1 then
      raise Exception.CreateFmt('Dispatch method callback: invalid argument count %d', [ArgCount]);

    if (JsGetValueType(Args^) <> JsObject) then
      raise Exception.Create('Dispatch method callback: thisarg not an object');

    Inc(Args);
    Dec(ArgCount);

    SetLength(VArgs, ArgCount);
    for I := 0 to ArgCount - 1 do
    begin
      VArgs[I] := JsValueToVariant(Args^);
      Inc(Args);
    end;

    Result := VariantToJsValue(Proxy.DispCall(JsStringToUnicodeString(JsGetProperty(Callee, 'name')), VArgs));
  except
    on E: Exception do
      JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function HasEnumVariant(const Disp: IDispatch; out Enum: IEnumVariant): Boolean;
const
  NewEnum: PWideChar = '_NewEnum';
var
  ID: Integer;
  Params: TDispParams;
  VEnum: Variant;
begin
  Result := False;
  if not Succeeded(Disp.GetIDsOfNames(GUID_NULL, @NewEnum, 1, LOCALE_NEUTRAL, @ID)) then
    Exit;

  FillChar(Params, SizeOf(TDispParams), 0);
  if not Succeeded(Disp.Invoke(ID, GUID_NULL, LOCALE_NEUTRAL, DISPATCH_PROPERTYGET, Params, @VEnum, nil, nil)) then
    Exit;
  Result := (TVarData(VEnum).VType = varUnknown) and Supports(IInterface(TVarData(VEnum).VUnknown), IEnumVariant, Enum);
end;

procedure Proxy_FinalizeCallback(data: Pointer); {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  TObject(data).Free;
end;

function DispToJsValue(const Disp: IDispatch): JsValueRef;
var
  EnumVariant: IEnumVARIANT;
  L: Integer;
  VArray: array of Variant;
  V: OleVariant;
  F: Cardinal;
  Proxy: TDispProxy;

begin
  if HasEnumVariant(Disp, EnumVariant) then
  begin
    VArray := nil;
    L := 0;

    while Succeeded(EnumVariant.Next(1, V, F)) do
    begin
      if F = 0 then
        Break;

      SetLength(VArray, L + 1);
      VArray[L] := V;
      Inc(L);
      V := Unassigned;
    end;
    Result := VariantToJsValue(VarArrayOf(VArray));
  end
  else
  begin
    Proxy := TDispProxy.Create(Disp);
    try
      Result := Proxy.Instance;
    except
      Proxy.Free;
      raise;
    end;
  end;
end;

{ TDispProxy private }

function TDispProxy.DispCall(const MethodName: WideString; const Args: array of Variant): Variant;
var
  MethodID: Integer;
  Params: TDispParams;
  ExcepInfo: TExcepInfo;
  Status: HResult;
begin
  Result := Unassigned;

  if not DispGetMemberID(MethodName, MethodID) then
    Exit;

  FillChar(Params, SizeOf(TDispParams), 0);
  Params.cArgs := Length(Args);
  if Params.cArgs > 0 then
    Params.rgvarg := @Args[0];
  Status := Disp.Invoke(MethodID, GUID_NULL, LOCALE_NEUTRAL, DISPATCH_METHOD, Params, @Result, @ExcepInfo, nil);
  if not Succeeded(Status) then
    DispatchInvokeError(Status, ExcepInfo);
end;

function TDispProxy.DispGetMemberID(const PropName: WideString; out PropID: Integer): Boolean;
var
  P: PWideChar;
begin
  PropID := -1;

  P := PWideChar(PropName);
  Result := Succeeded(Disp.GetIDsOfNames(GUID_NULL, @P, 1, LOCALE_NEUTRAL, @PropID));
end;

function TDispProxy.DispGetMethod(const MethodName: WideString; out Method: JsValueRef): Boolean;
var
  MethodID: Integer;
  Info: ITypeInfo;
  Attr: PTypeAttr;
  I, L: Integer;
  FuncDesc: PFuncDesc;
begin
  Result := False;
  Method := JsUndefinedValue;

  for I := Low(FMethods) to High(FMethods) do
    if JsStringToUnicodeString(JsGetProperty(FMethods[I], 'name')) = MethodName then
    begin
      Result := True;
      Method := FMethods[I];
      Exit;
    end;

  if not DispGetMemberID(MethodName, MethodID) then
    Exit;

  if not Succeeded(Disp.GetTypeInfo(0, LOCALE_NEUTRAL, Info)) or not Succeeded(Info.GetTypeAttr(Attr)) then
    Exit;
  try
    if Attr^.typekind <> TKIND_DISPATCH then
      Exit;

    for I := 0 to Attr^.cFuncs - 1 do
    begin
      FuncDesc := nil;
      if Succeeded(Info.GetFuncDesc(I, FuncDesc)) then
      try
        if (FuncDesc^.memid = MethodID) and (FuncDesc^.funckind = FUNC_DISPATCH) and (FuncDesc^.invkind = INVOKE_FUNC) and
          (FuncDesc^.wFuncFlags and FUNCFLAG_FRESTRICTED = 0) then
        begin
          Method := JsCreateFunction(Disp_MethodCallback, Self, MethodName);
          JsAddRef(Method);
          L := Length(FMethods);
          SetLength(FMethods, L + 1);
          FMethods[L] := Method;
          Result := True;
          Break;
        end;
      finally
        Info.ReleaseFuncDesc(FuncDesc);
      end;
    end;
  finally
    Info.ReleaseTypeAttr(Attr);
  end;
end;

function TDispProxy.DispPropGet(const PropName: WideString; out Value: Variant): Boolean;
var
  PropID: Integer;
  Params: TDispParams;
begin
  Result := False;
  Value := Unassigned;

  if not DispGetMemberID(PropName, PropID) then
    Exit;

  FillChar(Params, SizeOf(TDispParams), 0);
  Result := Succeeded(Disp.Invoke(PropID, GUID_NULL, LOCALE_NEUTRAL, DISPATCH_PROPERTYGET, Params, @Value, nil, nil));
end;

function TDispProxy.DispPropPut(const PropName: WideString; const Value: Variant; ByRef: Boolean): Boolean;
const
  Flags: array[Boolean] of Word = (DISPATCH_PROPERTYPUT, DISPATCH_PROPERTYPUTREF);
var
  PropID: Integer;
  Params: TDispParams;
begin
  Result := False;

  if not DispGetMemberID(PropName, PropID) then
    Exit;

  FillChar(Params, SizeOf(TDispParams), 0);
  Params.rgvarg := @Value;
  Params.cArgs := 1;
  Result := Succeeded(Disp.Invoke(PropID, GUID_NULL, LOCALE_NEUTRAL, Flags[ByRef], Params, nil, nil, nil));
end;

{ TDispProxy protected }

function TDispProxy.DoGet(Prop: JsValueRef): JsValueRef;
var
  V: Variant;
  PropName: WideString;
begin
  Result := JsUndefinedValue;
  PropName := JsStringToUnicodeString(Prop);
  if DispPropGet(PropName, V) then
    Result := VariantToJsValue(V)
  else if not DispGetMethod(PropName, Result) then
    Result := inherited DoGet(Prop);
end;

function TDispProxy.DoHas(Prop: JsValueRef): Boolean;
var
  PropID: Integer;
begin
  Result := DispGetMemberID(JsStringToUnicodeString(Prop), PropID) or
    inherited DoHas(Prop);
end;

function TDispProxy.DoOwnKeys: JsValueRef;
var
  Info: ITypeInfo;
  Attr: PTypeAttr;
  I: Integer;
  MemberNames: TStringList; // TUnicodeStringList
  FuncDesc: PFuncDesc;
  SName: WideString;
begin
  Result := JsUndefinedValue;

  MemberNames := nil;
  if not Succeeded(Disp.GetTypeInfo(0, LOCALE_NEUTRAL, Info)) or not Succeeded(Info.GetTypeAttr(Attr)) then
    Exit;
  try
    if (Attr^.typekind <> TKIND_DISPATCH) then
      Exit;
    MemberNames := TStringList.Create;
    MemberNames.Duplicates := dupIgnore;
    for I := 0 to Attr^.cFuncs - 1 do
    begin
      FuncDesc := nil;
      if Succeeded(Info.GetFuncDesc(I, FuncDesc)) then
      try
        if (FuncDesc^.funckind = FUNC_DISPATCH) and (FuncDesc^.wFuncFlags and FUNCFLAG_FRESTRICTED = 0) then
          if Succeeded(Info.GetDocumentation(FuncDesc^.memid, @SName, nil, nil, nil)) then
            try
              MemberNames.Add(SName);
            finally
              SName := '';
            end;
      finally
        Info.ReleaseFuncDesc(FuncDesc);
      end;
    end;

    if MemberNames.Count > 0 then
    begin
      Result := JsCreateArray(MemberNames.Count);
      for I := 0 to MemberNames.Count - 1 do
        JsArraySetElement(Result, I, StringToJsString(MemberNames[I]));
    end;
  finally
    Info.ReleaseTypeAttr(Attr);
    MemberNames.Free;
  end;
end;

function TDispProxy.DoSet(Prop, Value: JsValueRef): Boolean;
begin
  Result := DispPropPut(JsStringToUnicodeString(Prop), JsValueToVariant(Value)) or
    inherited DoSet(Prop, Value);
end;

{ TDispProxy public }

constructor TDispProxy.Create(const ADisp: IDispatch);
var
  ATarget: JsValueRef;
begin
  FDisp := ADisp;
  FMethods := nil;
  ChakraCoreCheck(JsCreateExternalObject(Self, Proxy_FinalizeCallback, ATarget));
  inherited Create(ATarget);
end;

destructor TDispProxy.Destroy;
var
  I: Integer;
begin
  if Assigned(FMethods) then
    for I := High(FMethods) downto Low(FMethods) do
      JsRelease(FMethods[I]);
  FMethods := nil;
  if Assigned(Target) then
    ChakraCommon.JsSetExternalData(Target, nil);
  inherited Destroy;
end;

end.