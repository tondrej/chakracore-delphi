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

unit ChakraCoreVarUtils;

{$include common.inc}

interface

uses
  Classes, SysUtils, Variants, SysConst,
{$ifdef HAS_WIDESTRUTILS}
  WideStrUtils,
{$endif}
  Compat, ChakraCommon, ChakraCore, ChakraCoreUtils;

const
  SupportedVarTypeCount = 12{$ifdef HAS_VARUINT64} + 1{$endif}{$ifdef HAS_VARUSTRING} + 1{$endif};
  SupportedVarTypes: array[0..SupportedVarTypeCount - 1] of TVarType = (
    varShortInt, varByte, varSmallInt, varWord, varInteger, varLongWord,
    varInt64, {$ifdef HAS_VARUINT64}varUInt64,{$endif}
    varBoolean,
    varSingle, varDouble,
    varString, {$ifdef HAS_VARUSTRING}varUString, {$endif}varOleStr);
  SupportedVarArrayTypes: array[0..9] of TVarType = (
    varShortInt, varByte, varSmallInt, varWord, varInteger, varLongWord,
    varBoolean,
    varSingle, varDouble,
    varOleStr);
  SupportedJsTypedArrayVarTypes: array[JsTypedArrayType] of TVarType = (
    varShortInt, // JsArrayTypeInt8
    varByte,     // JsArrayTypeUint8
    varByte,     // JsArrayTypeUint8Clamped
    varSmallInt, // JsArrayTypeInt16
    varWord,     // JsArrayTypeUint16
    varInteger,  // JsArrayTypeInt32
    varLongWord, // JsArrayTypeUint32
    varSingle,   // JsArrayTypeFloat32
    varDouble    // JsArrayTypeFloat64
  );

var
  varJsValue: Word = varEmpty;

type

  { TJsValueVariantType }

  TJsValueVariantType = class(TInvokeableVariantType)
  protected
    function FixupIdent(const AText: string): string; {$ifdef DELPHI}override;{$endif}
    procedure DispInvoke(Dest: PVarData; {$ifdef DELPHI}{$ifdef DELPHI2009_UP}[Ref] {$endif}const {$else}var{$endif} Source: TVarData;
      CallDesc: PCallDesc; Params: Pointer); override;
  public
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean); override;
    function DoFunction(var Dest: TVarData; const V: TVarData; const Name: string;
      const Arguments: TVarDataArray): Boolean; override;
    function DoProcedure(const V: TVarData; const Name: string; const Arguments: TVarDataArray): Boolean; override;
    function GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean; override;
{$ifdef DELPHI}
    function SetProperty(const V: TVarData; const Name: string; const Value: TVarData): Boolean; override;
{$else}
    function SetProperty(var V: TVarData; const Name: string; const Value: TVarData): Boolean; override;
{$endif}
  end;

function JsArrayToVariant(Value: JsValueRef): Variant;
function JsArrayTypeToVarType(AType: JsTypedArrayType): TVarType;
function JsNumberToVariant(Value: JsValueRef): Variant;
function JsNumberVarType(Value: JsValueRef; P: PVarData = nil): TVarType;
function JsTypedArrayToVariant(Value: JsValueRef): Variant;
function JsValueToVariant(Value: JsValueRef): Variant;
function VarDataArrayToJsValueArrray(const VarDataArray: TVarDataArray): JsValueRefArray;
function VariantToJsValue(const V: Variant): JsValueRef;
function VarTypeToJsArrayType(AVarType: TVarType; out AType: JsTypedArrayType): Boolean;

procedure JsValueVariant(AValue: JsValueRef; var Dest: TVarData); overload;
function JsValueVariant(AValue: JsValueRef): Variant; overload;

implementation

uses
{$ifdef WINDOWS}
  ChakraCoreDispClasses,
{$endif}
  VarUtils, Math;

const
  DISPATCH_METHOD      = $01;
  DISPATCH_PROPERTYGET = $02;
  DISPATCH_PROPERTYPUT = $04;

var
  _JsValueVariantType: TJsValueVariantType;

function JsArrayToVariant(Value: JsValueRef): Variant;
var
  L, I: Integer;
  VarType, CommonVarType: TVarType;
begin
  Result := Unassigned;

  case JsGetValueType(Value) of
    JsTypedArray:
      Result := JsTypedArrayToVariant(Value);
    JsArray:
      begin
        L := JsArrayLength(Value);
        case JsGetValueType(JsArrayGetElement(Value, 0)) of
          JsNumber:
            begin
              CommonVarType := varShortInt;
              for I := 0 to L - 1 do
              begin
                VarType := JsNumberVarType(JsArrayGetElement(Value, I));
                case VarType of
                  varShortInt:
                    ;
                  varSmallInt:
                    if CommonVarType = varShortInt then
                      CommonVarType := varSmallInt;
                  varInteger:
                    if CommonVarType in [varShortInt, varSmallInt] then
                      CommonVarType := varInteger;
                  // varInt64, varUInt64 not valid for varArray
                  varInt64, {$ifdef HAS_VARUINT64}varUInt64, {$endif}varSingle, varDouble, varCurrency:
                    if CommonVarType in [varShortInt, varSmallInt, varInteger] then
                      CommonVarType := varDouble;
                  else
                  begin
                    CommonVarType := varVariant;
                    Break;
                  end;
                end;
              end;

              Result := VarArrayCreate([0, L - 1], CommonVarType);
              for I := 0 to L - 1 do
                Result[I] := JsValueToVariant(JsArrayGetElement(Value, I));
            end;
          JsString:
            begin
              Result := VarArrayCreate([0, L - 1], varOleStr);
              for I := 0 to L - 1 do
                Result[I] := JsValueToVariant(JsArrayGetElement(Value, I));
            end;
          JsBoolean:
            begin
              Result := VarArrayCreate([0, L - 1], varBoolean);
              for I := 0 to L - 1 do
                Result[I] := JsValueToVariant(JsArrayGetElement(Value, I));
            end;
          JsObject:
            if JsInstanceOf(JsArrayGetElement(Value, 0), 'Date') then
            begin
              Result := VarArrayCreate([0, L - 1], varDate);
              for I := 0 to L - 1 do
                Result[I] := JsValueToVariant(JsArrayGetElement(Value, I));
            end;
        end;
      end;
  end;
end;

function JsArrayTypeToVarType(AType: JsTypedArrayType): TVarType;
const
  VTypes: array[JsTypedArrayType] of TVarType = (
    varShortInt, // JsArrayTypeInt8
    varByte,     // JsArrayTypeUint8
    varByte,     // JsArrayTypeUint8Clamped
    varSmallInt, // JsArrayTypeInt16
    varWord,     // JsArrayTypeUint16
    varInteger,  // JsArrayTypeInt32
    varLongWord, // JsArrayTypeUint32
    varSingle,   // JsArrayTypeFloat32
    varDouble    // JsArrayTypeFloat64
  );
begin
  Result := VTypes[AType];
end;

function JsNumberToVariant(Value: JsValueRef): Variant;
begin
  VarClear(Result);
  JsNumberVarType(Value, @Result);
end;

function JsNumberVarType(Value: JsValueRef; P: PVarData = nil): TVarType;
var
  D: Double;
  I: Int64;
begin
  Result := varEmpty;
  if JsGetValueType(Value) <> JsNumber then
    Exit;

  D := JsNumberToDouble(Value);
  if not JsNumberIsInteger(Value) then
  begin
    Result := varDouble;
    if Assigned(P) then
    begin
      P^.VType := Result;
      P^.VDouble := D;
    end;
    Exit;
  end;
  I := Trunc(D);

  if (I < Low(Integer)) or (I > High(Integer)) then
  begin
    Result := varInt64;
    if Assigned(P) then
    begin
      P^.VType := Result;
      P^.VInt64 := I;
    end;
  end
  else if (I < Low(SmallInt)) or (I > High(SmallInt)) then
  begin
    Result := varInteger;
    if Assigned(P) then
    begin
      P^.VType := Result;
      P^.VInteger := Integer(I);
    end;
  end
  else if (I < Low(ShortInt)) or (I > High(ShortInt)) then
  begin
    Result := varSmallInt;
    if Assigned(P) then
    begin
      P^.VType := varSmallint;
      P^.VSmallInt := SmallInt(I);
    end;
  end
  else
  begin
    Result := varShortInt;
    if Assigned(P) then
    begin
      P^.VType := Result;
      P^.VShortInt := ShortInt(I);
    end;
  end;
end;

function JsTypedArrayToVariant(Value: JsValueRef): Variant;
var
  Buf: ChakraBytePtr;
  BufLen: Cardinal;
  AType: JsTypedArrayType;
  ElemSize: Integer;
  VType: TVarType;
  P: Pointer;
begin
  Buf := nil;
  BufLen := 0;
  ChakraCoreCheck(JsGetTypedArrayStorage(Value, Buf, BufLen, AType, ElemSize));
  if not Assigned(Buf) or (BufLen = 0) then
  begin
    Result := Unassigned;
    Exit;
  end;

  VType := JsArrayTypeToVarType(AType);
  Result := VarArrayCreate([0, BufLen div ElemSize - 1], VType);
  P := VarArrayLock(Result);
  try
    Move(Buf^, P^, BufLen);
  finally
    VarArrayUnlock(Result);
  end;
end;

function JsValueToVariant(Value: JsValueRef): Variant;
var
  Buf, P: ChakraBytePtr;
  BufLen: Cardinal;
begin
  VarClear(Result);

  case JsGetValueType(Value) of
    JsUndefined:
      Result := Unassigned;
    JsNull:
      Result := Null;
    JsNumber:
      Result := JsNumberToVariant(Value);
    JsString:
      Result := VarAsType(JsStringToUnicodeString(Value), varOleStr);
    JsBoolean:
      Result := JsBooleanToBoolean(Value);
    JsObject:
      if JsInstanceOf(Value, 'Date') then
        Result := JsDateToDateTime(Value)
      else
        Result := JsValueVariant(Value);
    JsFunction:
      begin
        TVarData(Result).VType := varJsValue;
        TVarData(Result).VPointer := Value;
      end;
    JsError:
      begin
        TVarData(Result).VType := varError;
        TVarData(Result).VError := 0; // TODO JsErrorToHResult();
      end;
    JsArray:
      Result := JsArrayToVariant(Value);
    JsArrayBuffer:
      begin
        Buf := nil;
        BufLen := 0;
        ChakraCoreCheck(JsGetArrayBufferStorage(Value, Buf, BufLen));
        if not Assigned(Buf) or (BufLen = 0) then
          Exit;

        Result := VarArrayCreate([0, BufLen - 1], varByte);
        P := VarArrayLock(Result);
        try
          Move(Buf^, P^, BufLen);
        finally
          VarArrayUnlock(Result);
        end;
      end;
    JsTypedArray:
      Result := JsTypedArrayToVariant(Value);
    JsDataView:
      begin
        Buf := nil;
        BufLen := 0;
        ChakraCoreCheck(JsGetDataViewStorage(Value, Buf, BufLen));
        if not Assigned(Buf) or (BufLen = 0) then
          Exit;

        Result := VarArrayCreate([0, BufLen - 1], varByte);
        P := VarArrayLock(Result);
        try
          Move(Buf^, P^, BufLen);
        finally
          VarArrayUnlock(Result);
        end;
      end;
  end;
end;

function VarDataArrayToJsValueArrray(const VarDataArray: TVarDataArray): JsValueRefArray;
var
  L, I: Integer;
begin
  Result := nil;
  L := Length(VarDataArray);
  if L = 0 then
    Exit;

  SetLength(Result, L);
  for I := Low(VarDataArray) to High(VarDataArray) do
    Result[I] := VariantToJsValue(Variant(VarDataArray[I]));
end;

function VariantToJsValue(const V: Variant): JsValueRef;
var
  D, ElemSize, I, L: Integer;
  AType: JsTypedArrayType;
  Buf: ChakraBytePtr;
  BufLen: Cardinal;
  P: Pointer;
begin
  Result := JsUndefinedValue;

  if VarIsArray(V) then
  begin
    D := VarArrayDimCount(V);
    if D = 1 then
    begin
      if VarTypeToJsArrayType(VarType(V) and VarTypeMask, AType) then
      begin
        Result := JsCreateNativeTypedArray(AType, VarArrayHighBound(V, 1) - VarArrayLowBound(V, 1) + 1);

        Buf := nil;
        BufLen := 0;
        ChakraCoreCheck(JsGetTypedArrayStorage(Result, Buf, BufLen, AType, ElemSize));
        if not Assigned(Buf) or (BufLen = 0) then
          Exit;

        P := VarArrayLock(V);
        try
          Move(P^, Buf^, BufLen);
        finally
          VarArrayUnlock(V);
        end;
      end
      else // non-typed array
      begin
(*
        case VarType(V) and VarTypeMask of
          varInt64, {$ifdef HAS_VARUINT64}varUInt64, {$endif}varBoolean, varCurrency, varDate,
            varString, {$ifdef HAS_VARUSTRING}varUString, {$endif}varOleStr, varVariant:
            begin
*)
              L := VarArrayHighBound(V, 1) - VarArrayLowBound(V, 1) + 1;
              Result := JsCreateArray(L);
              for I := 0 to L - 1 do
                JsArraySetElement(Result, I, VariantToJsValue(VarArrayGet(V, [I])));
(*
            end;
        end;
*)
      end;
    end
    else // TODO multi-dimensional array
      Exit;
  end
  else if VarType(V) = varVariant or varByRef then
    Result := VariantToJsValue(Variant(FindVarData(V)^))
  else
  begin
    case VarType(V) and VarTypeMask of
      varEmpty:
        Result := JsUndefinedValue;
      varNull:
        Result := JsNullValue;
      varShortInt:
        Result := IntToJsNumber(ShortInt(V));
      varByte:
        Result := IntToJsNumber(Byte(V));
      varSmallInt:
        Result := IntToJsNumber(SmallInt(V));
      varWord:
        Result := IntToJsNumber(Word(V));
      varInteger:
        Result := IntToJsNumber(Integer(V));
      varLongWord:
        Result := DoubleToJsNumber(Double(V));
      varInt64:
        Result := DoubleToJsNumber(Double(V));
{$ifdef HAS_VARUINT64}
      varUInt64:
        Result := DoubleToJsNumber(Double(V));
{$endif}
      varBoolean:
        Result := BooleanToJsBoolean(Boolean(V));
      varSingle:
        Result := DoubleToJsNumber(Single(V));
      varDouble:
        Result := DoubleToJsNumber(Double(V));
      varCurrency:
        Result := DoubleToJsNumber(Currency(V));
      varDate:
        Result := DateTimeToJsDate(TDateTime(V));
      varString:
        Result := StringToJsString(UTF8String(V));
      {$ifdef HAS_VARUSTRING}varUString, {$endif}varOleStr:
        Result := StringToJsString(UnicodeString(V));
      varError:
        Result := JsCreateError('', etGenericError); // TODO? message from TVarData.VError (HResult)
{$ifdef WINDOWS}
      varDispatch:
        Result := DispToJsValue(IDispatch(TVarData(V).VDispatch));
{$endif}
      else if VarType(V) and VarTypeMask = varJsValue then
        Result := TVarData(V).VPointer
      else
        raise EChakraCore.CreateFmt('Unsupported variant type %u', [VarType(V) and VarTypeMask]);
    end;
  end;
end;

function VarTypeToJsArrayType(AVarType: TVarType; out AType: JsTypedArrayType): Boolean;
begin
  Result := False;

  case AVarType of
    varShortInt:
      AType := JsArrayTypeInt8;
    varByte:
      AType := JsArrayTypeUint8;
    varSmallInt:
      AType := JsArrayTypeInt16;
    varWord:
      AType := JsArrayTypeUInt16;
    varInteger:
      AType := JsArrayTypeInt32;
    varLongWord:
      AType := JsArrayTypeUint32;
    varSingle:
      AType := JsArrayTypeFloat32;
    varDouble:
      AType := JsArrayTypeFloat64;
    else
      Exit;
  end;

  Result := True;
end;

{ TJsValueVariantType }

procedure JsValueVariant(AValue: JsValueRef; var Dest: TVarData);
begin
  VarClear(Variant(Dest));
  Dest.VType := varJsValue;
  Dest.VPointer := AValue;
  JsAddRef(AValue);
end;

function JsValueVariant(AValue: JsValueRef): Variant;
begin
  JsValueVariant(AValue, TVarData(Result));
end;

function TJsValueVariantType.FixupIdent(const AText: string): string;
begin
  Result := AText;
end;

{$ifdef DELPHI}

procedure TJsValueVariantType.DispInvoke(Dest: PVarData; {$ifdef DELPHI2009_UP}[Ref] {$endif}const Source: TVarData;
  CallDesc: PCallDesc; Params: Pointer);
{$ifndef HAS_GETDISPATCHINVOKEARGS}
type
  PParamRec = ^TParamRec;
  TParamRec = array[0..3] of LongInt;
  TStringDesc = record
    BStr: WideString;
    PStr: PAnsiString;
  end;
  TStringRefList = array of TStringDesc;

  function GetDispatchInvokeArgs(CallDesc: PCallDesc; Params: Pointer; var Strings: TStringRefList; Dummy: Boolean): TVarDataArray;
  var
    StrCount: Integer;
    ParamPtr: Pointer;

    procedure ParseParam(I: Integer);
    const
      CArgTypeMask    = $7F;
      CArgByRef       = $80;
    var
      LArgType: Integer;
      LArgByRef: Boolean;
    begin
      LArgType := CallDesc^.ArgTypes[I] and CArgTypeMask;
      LArgByRef := (CallDesc^.ArgTypes[I] and CArgByRef) <> 0;

      if LArgType = varError then
      begin
        Result[I].VType := varError;
        Result[I].VError := VAR_PARAMNOTFOUND;
      end
      else if LArgType = varStrArg then
      begin
        with Strings[StrCount] do
          if LArgByRef then
          begin
            BStr := WideString(System.Copy(PAnsiString(ParamPtr^)^, 1, MaxInt));
            PStr := PAnsiString(ParamPtr^);
            Result[I].VType := varOleStr or varByRef;
            Result[I].VOleStr := @BStr;
          end
          else
          begin
            BStr := WideString(System.Copy(PAnsiString(ParamPtr)^, 1, MaxInt));
            PStr := nil;
            Result[I].VType := varOleStr;
            Result[I].VOleStr := PWideChar(BStr);
          end;
        Inc(StrCount);
      end
      else if LArgByRef then
      begin
        if (LArgType = varVariant) and
           ((PVarData(ParamPtr^)^.VType = varString){$ifdef HAS_VARUSTRING} or (PVarData(ParamPtr^)^.VType = varUString){$endif}) then
          VarDataCastTo(PVarData(ParamPtr^)^, PVarData(ParamPtr^)^, varOleStr);
        Result[I].VType := LArgType or varByRef;
        Result[I].VPointer := Pointer(ParamPtr^);
      end
      else if LArgType = varVariant then
        if (PVarData(ParamPtr)^.VType = varString){$ifdef HAS_VARUSTRING} or
           (PVarData(ParamPtr)^.VType = varUString){$endif} then
        begin
          with Strings[StrCount] do
          begin
{$ifdef HAS_VARUSTRING}
            if (PVarData(ParamPtr)^.VType = varString) then
              BStr := WideString(System.Copy(AnsiString(PVarData(ParamPtr)^.VString), 1, MaxInt))
            else
              BStr := System.Copy(UnicodeString(PVarData(ParamPtr)^.VUString), 1, MaxInt);
{$else}
            BStr := System.Copy(AnsiString(PVarData(ParamPtr)^.VString), 1, MaxInt);
{$endif}
            PStr := nil;
            Result[I].VType := varOleStr;
            Result[I].VOleStr := PWideChar(BStr);
          end;
          Inc(StrCount);
        end
        else
        begin
          Result[I] := PVarData(ParamPtr)^;
          Inc(Integer(ParamPtr), SizeOf(TVarData) - SizeOf(Pointer));
        end
      else
      begin
        Result[I].VType := LArgType;
        case CVarTypeToElementInfo[LArgType].Size of
          1, 2, 4:
            Result[I].VLongs[1] := PParamRec(ParamPtr)^[0];
          8:
            begin
              Result[I].VLongs[1] := PParamRec(ParamPtr)^[0];
              Result[I].VLongs[2] := PParamRec(ParamPtr)^[1];
              Inc(Integer(ParamPtr), 8 - SizeOf(Pointer));
            end;
        else
          RaiseDispError;
        end;
      end;
      Inc(Integer(ParamPtr), SizeOf(Pointer));
    end;
  var
    I: Integer;
  begin
    // Parse the arguments
    ParamPtr := Params;
    SetLength(Result, CallDesc^.ArgCount);
    StrCount := 0;
    SetLength(Strings, CallDesc^.ArgCount);
    for I := 0 to CallDesc^.ArgCount - 1 do
      ParseParam(I);
  end;
{$endif}

{$ifndef HAS_FINALIZEDISPATCHINVOKEARGS}
  procedure FinalizeDispatchInvokeArgs(CallDesc: PCallDesc; const Args: TVarDataArray; OrderLTR : Boolean);
  const
    atByRef    = $80;
  var
    I: Integer;
    ArgType: Byte;
    PVarParm: PVarData;
    VType: TVarType;
  begin
    for I := 0 to CallDesc^.ArgCount-1 do
    begin
      ArgType := CallDesc^.ArgTypes[I];

      if OrderLTR then
        PVarParm := @Args[I]
      else
        PVarParm := @Args[CallDesc^.ArgCount-I-1];

      VType := PVarParm.VType;

      // Only ByVal Variant or Array parameters have been copied and need to be released
      // Strings have been released via the use of the TStringRefList parameter to GetDispatchInvokeArgs
      if ((ArgType and atByRef) <> atByRef) and ((VType = varVariant) or ((VType and varArray) = varArray)) then
        VarClear(PVariant(PVarParm)^);
    end;
  end;
{$endif}
var
  PIdent: PByte;
  LIdent: string;
  VarParams : TVarDataArray;
  Strings: TStringRefList;
  DestValue: JsValueRef;
begin
  // array element get
  if (CallDesc^.CallType = 2) and (CallDesc^.ArgCount = 1) and (JsGetValueType(Source.VPointer) = JsObject) then
  begin
    PIdent := @CallDesc^.ArgTypes[CallDesc^.ArgCount];
    LIdent := FixupIdent(UTF8ToString(PAnsiChar(PIdent)));
    FillChar(Strings, SizeOf(Strings), 0);
    VarParams := GetDispatchInvokeArgs(CallDesc, Params, Strings, true);
    try
      DestValue := JsGetProperty(Source.VPointer, LIdent);
      if JsGetValueType(DestValue) in [JsArray, JsTypedArray] then
      begin
        Variant(Dest^) := JsValueToVariant(JsArrayGetElement(DestValue, VarParams[0].VInteger));
        Exit;
      end;
    finally
      FinalizeDispatchInvokeArgs(CallDesc, VarParams, True);
    end;
  end
  // array element set
  else if (CallDesc^.CallType = 4) and (CallDesc^.ArgCount = 2) and (JsgetValueType(Source.VPointer) = JsObject) then
  begin
    PIdent := @CallDesc^.ArgTypes[CallDesc^.ArgCount];
    LIdent := FixupIdent(UTF8ToString(PAnsiChar(PIdent)));
    FillChar(Strings, SizeOf(Strings), 0);
    VarParams := GetDispatchInvokeArgs(CallDesc, Params, Strings, true);
    try
      DestValue := JsGetProperty(Source.VPointer, LIdent);
      if JsGetValueType(DestValue) in [JsArray, JsTypedArray] then
      begin
        JsArraySetElement(DestValue, PInteger(Params)^, VariantToJsValue(Variant(VarParams[1])));
        Exit;
      end;
    finally
      FinalizeDispatchInvokeArgs(CallDesc, VarParams, True);
    end;
  end;

  inherited DispInvoke(Dest, Source, CallDesc, Params);
end;
{$else} // ifndef DELPHI

function GetDispatchInvokeArgs(CallDesc: PCallDesc; Params: Pointer): TVarDataArray;
const
  ArgTypeMask = $7F;
  ArgRefMask = $80;
var
  I: Integer;
  ArgPtr: Pointer;
  ArgType: Byte;
  ArgByRef: Boolean;
  ArgData: PVarData;
  ArgAdvanced: Boolean;
begin
  SetLength(Result, CallDesc^.ArgCount);
  if CallDesc^.ArgCount = 0 then
    Exit;

  ArgPtr := Params;
  for I := 0 to CallDesc^.ArgCount - 1 do
  begin
    ArgType := CallDesc^.ArgTypes[I] and ArgTypeMask;
    ArgByRef := (CallDesc^.ArgTypes[I] and ArgRefMask) <> 0;
    ArgData := @Result[CallDesc^.ArgCount - I - 1];
    case ArgType of
      varUStrArg: ArgData^.vType := varUString;
      varStrArg: ArgData^.vType := varString;
    else
      ArgData^.vType := ArgType
    end;
    if ArgByRef then
    begin
      ArgData^.vType := ArgData^.vType or varByRef;
      ArgData^.vPointer := PPointer(ArgPtr)^;
      Inc(ArgPtr, SizeOf(Pointer));
    end
    else
      begin
        ArgAdvanced := False;
        case ArgType of
          varError:
            begin
              ArgData^.vError := VAR_PARAMNOTFOUND;
              ArgAdvanced := True;
            end;
          varVariant:
            ArgData^ := PVarData(PPointer(ArgPtr)^)^;
          varDouble, varCurrency, varDate, varInt64, varQWord:
            begin
              ArgData^.vQWord := PQWord(ArgPtr)^; // 64bit on all platforms
              Inc(ArgPtr, SizeOf(QWord));
              ArgAdvanced := true;
            end;
          { values potentially smaller than sizeof(pointer) must be handled
            explicitly to guarantee endian safety and to prevent copying/
            skipping data (they are always copied into a 4 byte element
            by the compiler, although it will still skip sizeof(pointer)
            bytes afterwards) }
          varSingle:
            ArgData^.vSingle := PSingle(ArgPtr)^;
          varSmallint:
            ArgData^.vSmallInt := PLongint(ArgPtr)^;
          varInteger:
            ArgData^.vInteger := PLongint(ArgPtr)^;
          varBoolean:
            ArgData^.vBoolean := WordBool(PLongint(ArgPtr)^);
          varShortInt:
            ArgData^.vShortInt := PLongint(ArgPtr)^;
          varByte:
            ArgData^.vByte := PLongint(ArgPtr)^;
          varWord:
            ArgData^.vWord := PLongint(ArgPtr)^;
          else
            ArgData^.vAny := PPointer(ArgPtr)^; // 32 or 64bit
        end;
        if not ArgAdvanced then
          Inc(ArgPtr, SizeOf(Pointer));
      end;
  end;
end;

procedure TJsValueVariantType.DispInvoke(Dest: PVarData; var Source: TVarData; CallDesc: PCallDesc; Params: Pointer);
var
  MethodName: ansistring;
  VarParams: TVarDataArray;
  DestValue: JsValueRef;
begin
  // array element get
  if (CallDesc^.CallType = DISPATCH_PROPERTYGET) and (CallDesc^.ArgCount = 1) and
    (JsGetValueType(Source.VPointer) = JsObject) then
  begin
    MethodName := AnsiString(PChar(@CallDesc^.ArgTypes[CallDesc^.ArgCount]));
    VarParams := GetDispatchInvokeArgs(CallDesc, Params);
    DestValue := JsGetProperty(Source.VPointer, MethodName);
    if JsGetValueType(DestValue) in [JsArray, JsTypedArray] then
    begin
      Variant(Dest^) := JsValueToVariant(JsArrayGetElement(DestValue, VarParams[0].VInteger));
      Exit;
    end;
  end
  // array element set
  else if (CallDesc^.CallType = DISPATCH_PROPERTYPUT) and (CallDesc^.ArgCount = 2) and
    (JsgetValueType(Source.VPointer) = JsObject) then
  begin
    MethodName := AnsiString(PChar(@CallDesc^.ArgTypes[CallDesc^.ArgCount]));
    VarParams := GetDispatchInvokeArgs(CallDesc, Params);
    DestValue := JsGetProperty(Source.VPointer, MethodName);
    if JsGetValueType(DestValue) in [JsArray, JsTypedArray] then
    begin
      JsArraySetElement(DestValue, VarParams[0].VInteger, VariantToJsValue(Variant(VarParams[1])));
      Exit;
    end;
  end;

  inherited DispInvoke(Dest, Source, CallDesc, Params);
end;

{$endif} // ifndef DELPHI

procedure TJsValueVariantType.Clear(var V: TVarData);
begin
  JsRelease(V.VPointer);
  V.VType := varEmpty;
end;

procedure TJsValueVariantType.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: Boolean);
begin
  JsValueVariant(Source.VPointer, Dest);
  JsAddRef(Source.VPointer);
end;

function TJsValueVariantType.DoFunction(var Dest: TVarData; const V: TVarData; const Name: string; const Arguments: TVarDataArray): Boolean;
begin
  Variant(Dest) := JsValueToVariant(JsCallFunction(Name, VarDataArrayToJsValueArrray(Arguments), V.VPointer));
  Result := True;
end;

function TJsValueVariantType.DoProcedure(const V: TVarData; const Name: string; const Arguments: TVarDataArray): Boolean;
begin
  JsCallFunction(Name, VarDataArrayToJsValueArrray(Arguments), V.VPointer);
  Result := True;
end;

function TJsValueVariantType.GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): Boolean;
begin
  Variant(Dest) := JsValueToVariant(JsGetProperty(V.VPointer, Name));
  Result := True;
end;

{$ifdef DELPHI}
function TJsValueVariantType.SetProperty(const V: TVarData; const Name: string; const Value: TVarData): Boolean;
{$else}
function TJsValueVariantType.SetProperty(var V: TVarData; const Name: string; const Value: TVarData): Boolean;
{$endif}
begin
  if Value.VType = varEmpty then // undefined
    JsDeleteProperty(V.VPointer, Name)
  else
    JsSetProperty(V.VPointer, Name, VariantToJsValue(Variant(Value)));
  Result := True;
end;

initialization
  _JsValueVariantType := TJsValueVariantType.Create;
  varJsValue := _JsValueVariantType.VarType;

finalization
  FreeAndNil(_JsValueVariantType);
  varJsValue := varEmpty;

end.
