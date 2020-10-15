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

unit Test_Variants;

interface

{$include ..\src\common.inc}

uses
  Classes, SysUtils, TypInfo, Variants,
{$ifdef FPC}
{$ifndef WINDOWS}
  cwstring,
{$endif}
  fpcunit, testregistry,
{$else}
  TestFramework,
{$endif}
  Compat, ChakraCommon, ChakraCore, ChakraCoreUtils, ChakraCoreVarUtils,
  Test_ChakraCore;

type

  { TSimpleVariantToJs }

  TSimpleVariantToJs = class(TChakraCoreTestCase)
  published
    procedure TestEmpty;
    procedure TestNull;
    procedure TestShortInt;
    procedure TestByte;
    procedure TestSmallInt;
    procedure TestWord;
    procedure TestInteger;
    procedure TestLongWord;
    procedure TestInt64;
    procedure TestUInt64;
    procedure TestBoolean;
    procedure TestSingle;
    procedure TestDouble;
    procedure TestCurrency;
    procedure TestDate;
    procedure TestString;
    procedure TestOleStr;
    procedure TestError;
  end;

  { TSimpleVarArrayToJs }

  TSimpleVarArrayToJs = class(TChakraCoreTestCase)
  published
    procedure TestShortIntArray;
    procedure TestByteArray;
    procedure TestSmallIntArray;
    procedure TestWordArray;
    procedure TestIntegerArray;
    procedure TestLongWordArray;
    // procedure TestInt64Array;
    // procedure TestUInt64Array;
    procedure TestBooleanArray;
    procedure TestSingleArray;
    procedure TestDoubleArray;
    procedure TestCurrencyArray;
    procedure TestDateArray;
    // procedure TestStringArray;
    procedure TestOleStrArray;
  end;

  { TSimpleJsToVariant }

  TSimpleJsToVariant = class(TChakraCoreTestCase)
  published
    procedure TestUndefined;
    procedure TestNull;
    procedure TestShortInt;
    procedure TestByte;
    procedure TestSmallInt;
    procedure TestWord;
    procedure TestInteger;
    procedure TestLongWord;
    procedure TestInt64;
    procedure TestUInt64;
    procedure TestBoolean;
    procedure TestSingle;
    procedure TestDouble;
    procedure TestCurrency;
    procedure TestDate;
    procedure TestString;
    procedure TestOleStr;
    procedure TestError;
  end;

  { TSimpleJsArrayToVariant }

  TSimpleJsArrayToVariant = class(TChakraCoreTestCase)
  published
    procedure TestShortIntArray;
    procedure TestByteArray;
    procedure TestSmallIntArray;
    procedure TestWordArray;
    procedure TestIntegerArray;
    procedure TestLongWordArray;
    // procedure TestInt64Array;
    // procedure TestUInt64Array;
    procedure TestBooleanArray;
    procedure TestSingleArray;
    procedure TestDoubleArray;
    procedure TestCurrencyArray;
    procedure TestDateArray;
    // procedure TestStringArray;
    procedure TestOleStrArray;
  end;

  { TJsValueVariant }

  TJsValueVariant = class(TChakraCoreTestCase)
  published
    procedure Properties;
    procedure Functions;
    procedure JsMath;
  end;

implementation

uses
  Math;

{ TSimpleVariantToJs }

procedure TSimpleVariantToJs.TestEmpty;
var
  V: Variant;
  Value: JsValueRef;
begin
  V := Unassigned;
  CheckEquals(varEmpty, VarType(V));

  Value := VariantToJsValue(V);
  CheckValueType(JsUndefined, Value, 'VariantToJsValue(Unassigned) value type');
end;

procedure TSimpleVariantToJs.TestNull;
var
  V: Variant;
  Value: JsValueRef;
begin
  V := Null;
  CheckEquals(varNull, VarType(V));

  Value := VariantToJsValue(V);
  CheckValueType(JsNull, Value, 'VariantToJsValue(Null) value type');
end;

procedure TSimpleVariantToJs.TestShortInt;
const
  MinValue = Low(ShortInt);
  MaxValue = High(ShortInt);
  TestValues: array[0..6] of ShortInt = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals(varShortInt, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    CheckEquals(TestValues[I], JsNumberToInt(Value), Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestByte;
const
  MinValue = Low(Byte);
  MaxValue = High(Byte);
  TestValues: array[0..6] of Byte = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals(varByte, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    CheckEquals(TestValues[I], JsNumberToInt(Value), Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestSmallInt;
const
  MinValue = Low(SmallInt);
  MaxValue = High(SmallInt);
  TestValues: array[0..6] of SmallInt = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals(varSmallInt, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    CheckEquals(TestValues[I], JsNumberToInt(Value), Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestWord;
const
  MinValue = Low(Word);
  MaxValue = High(Word);
  TestValues: array[0..6] of Word = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals(varWord, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    CheckEquals(TestValues[I], JsNumberToInt(Value), Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestInteger;
const
  MinValue = Low(Integer);
  MaxValue = High(Integer);
  TestValues: array[0..6] of Integer = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals(varInteger, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    CheckEquals(TestValues[I], JsNumberToInt(Value), Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestLongWord;
const
  MinValue = Low(LongWord);
  MaxValue = High(LongWord);
  TestValues: array[0..6] of LongWord = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals(varLongWord, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    CheckEquals(TestValues[I], LongWord(JsNumberToInt(Value)), Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestInt64;
const
  MinValue = MIN_SAFE_INTEGER;
  MaxValue = MAX_SAFE_INTEGER;
  TestValues: array[0..6] of Int64 = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
  Expected, Actual: Extended;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals(varInt64, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    Expected := TestValues[I];
    Actual := JsNumberToDouble(Value);
    CheckEquals(Expected, Actual, Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestUInt64;
const
  MaxValue = MAX_SAFE_INTEGER;
  TestValues: array[0..4] of UInt64 = (0, MaxValue div 4, MaxValue div 2, MaxValue div 2 + MaxValue div 4,
    UInt64(MaxValue));
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
  Expected, Actual: UInt64;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals({$ifdef HAS_VARUINT64}varUInt64{$else}varInt64{$endif}, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    Expected := TestValues[I];
    Actual := Round(JsNumberToDouble(Value));
    CheckEquals(UInt64(Expected), UInt64(Actual), Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestBoolean;
var
  B: Boolean;
  V: Variant;
  Value: JsValueRef;
begin
  for B := Low(Boolean) to High(Boolean) do
  begin
    V := B;
    CheckEquals(varBoolean, VarType(V), Format('vartype %s', [BoolToStr(B)]));

    Value := VariantToJsValue(V);
    CheckValueType(JsBoolean, Value, Format('value type %s', [BoolToStr(B)]));
    CheckEquals(B, JsBooleanToBoolean(Value), Format('value %s', [BoolToStr(B)]));
  end;
end;

procedure TSimpleVariantToJs.TestSingle;
const
  TestValues: array[0..9] of Single = (NaN, Infinity, NegInfinity, 1.5e-45, -10100100.101, -42, 0, 42,
    20200200.202, 3.4e3);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
  Expected, Actual: Extended;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := VarAsType(TestValues[I], varSingle);
    CheckEquals(varSingle, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    Expected := TestValues[I];
    Actual := JsNumberToDouble(Value);
    CheckEquals(Expected, Actual, Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestDouble;
const
  TestValues: array[0..9] of Double = (NaN, Infinity, NegInfinity, 1.5e-45, -10100100.101, -42, 0, 42,
    20200200.202, 3.4e3);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
  Expected, Actual: Extended;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals(varDouble, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    Expected := TestValues[I];
    Actual := JsNumberToDouble(Value);
    CheckEquals(Expected, Actual, Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestCurrency;
const
  TestValues: array[0..6] of Currency = (-999999.99, -100000, -5389, 0, 42, 10234, 999999.99);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
  Expected, Actual: Extended;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := TestValues[I];
    CheckEquals(varCurrency, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsNumber, Value, Format('value type %d', [I]));
    Expected := TestValues[I];
    Actual := JsNumberToDouble(Value);
    CheckEquals(Expected, Actual, Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestDate;
const
  TestValues: array[0..3] of TSystemTime = (
    (Year: 1970; Month:  1; Day:  1; Hour:  9; Minute: 30; Second: 25; MilliSecond: 300),
    (Year:  447; Month:  5; Day: 13; Hour: 23; Minute: 19; Second:  2; MilliSecond: 455),
    (Year: 2020; Month:  4; Day: 27; Hour: 19; Minute:  4; Second: 13; MilliSecond:  11),
    (Year: 2525; Month: 11; Day:  1; Hour:  3; Minute:  7; Second: 55; MilliSecond: 127)
  );
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := SystemTimeToDateTime(TestValues[I]);
    CheckEquals(varDate, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsObject, Value, Format('value type %d', [I]));
    CheckTrue(JsInstanceOf(Value, 'Date'), Format('value %d instanceof Date', [I]));

    CheckEquals(TestValues[I].Year,        JsNumberToInt(JsCallFunction('getUTCFullYear',     [], Value)), Format('value %d getUTCFullYear',     [I]));
    CheckEquals(TestValues[I].Month - 1,   JsNumberToInt(JsCallFunction('getUTCMonth',        [], Value)), Format('value %d getUTCMonth',        [I]));
    CheckEquals(TestValues[I].Day,         JsNumberToInt(JsCallFunction('getUTCDate',         [], Value)), Format('value %d getUTCDate',         [I]));
    CheckEquals(TestValues[I].Hour,        JsNumberToInt(JsCallFunction('getUTCHours',        [], Value)), Format('value %d getUTCHours',        [I]));
    CheckEquals(TestValues[I].Minute,      JsNumberToInt(JsCallFunction('getUTCMinutes',      [], Value)), Format('value %d getUTCMinutes',      [I]));
    CheckEquals(TestValues[I].Second,      JsNumberToInt(JsCallFunction('getUTCSeconds',      [], Value)), Format('value %d getUTCSeconds',      [I]));
    CheckEquals(TestValues[I].MilliSecond, JsNumberToInt(JsCallFunction('getUTCMilliseconds', [], Value)), Format('value %d getUTCMilliseconds', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestString;
const
  TestValues: array[0..6] of UnicodeString = (
    'Hello, world!',
    'Hola món!',
    'Witaj świecie!',
    'Привет, мир!',
    'مرحبا بالعالم!',
    'ওহে বিশ্ব!',
    '你好，世界！'
  );
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := VarAsType(UTF8Encode(TestValues[I]), varString);
    CheckEquals(varString, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsString, Value, Format('value type %d', [I]));
    CheckEquals(TestValues[I], JsStringToUnicodeString(Value), Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestOleStr;
const
  TestValues: array[0..6] of UnicodeString = (
    'Hello, world!',
    'Hola món!',
    'Witaj świecie!',
    'Привет, мир!',
    'مرحبا بالعالم!',
    'ওহে বিশ্ব!',
    '你好，世界！'
  );
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    V := VarAsType(TestValues[I], varOleStr);
    CheckEquals(varOleStr, VarType(V), Format('vartype %d', [I]));

    Value := VariantToJsValue(V);
    CheckValueType(JsString, Value, Format('value type %d', [I]));
    CheckEquals(TestValues[I], JsStringToUnicodeString(Value), Format('value %d', [I]));
  end;
end;

procedure TSimpleVariantToJs.TestError;
var
  V: Variant;
  Value: JsValueRef;
begin
  TVarData(V).VType := varError;
  TVarData(V).VError := S_OK;

  Value := VariantToJsValue(V);
  CheckValueType(JsError, Value, 'vartype');
  // TODO CheckEquals(error_message, JsStringToUnicodeString(JsGetProperty(Value, 'message')));
end;

{ TSimpleVarArrayToJs }

procedure TSimpleVarArrayToJs.TestShortIntArray;
const
  MinValue = Low(ShortInt);
  MaxValue = High(ShortInt);
  TestValues: array[0..6] of ShortInt = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varShortInt);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsTypedArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsNumber, ElemValue, Format('element %d value type', [I]));
    CheckEquals(TestValues[I], ShortInt(JsNumberToInt(ElemValue)), Format('element %d value', [I]));
  end;
end;

procedure TSimpleVarArrayToJs.TestByteArray;
const
  MinValue = Low(Byte);
  MaxValue = High(Byte);
  TestValues: array[0..6] of Byte = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varByte);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsTypedArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsNumber, ElemValue, Format('element %d value type', [I]));
    CheckEquals(TestValues[I], Byte(JsNumberToInt(ElemValue)), Format('element %d value', [I]));
  end;
end;

procedure TSimpleVarArrayToJs.TestSmallIntArray;
const
  MinValue = Low(SmallInt);
  MaxValue = High(SmallInt);
  TestValues: array[0..6] of SmallInt = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varSmallInt);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsTypedArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsNumber, ElemValue, Format('element %d value type', [I]));
    CheckEquals(TestValues[I], SmallInt(JsNumberToInt(ElemValue)), Format('element %d value', [I]));
  end;
end;

procedure TSimpleVarArrayToJs.TestWordArray;
const
  MinValue = Low(Word);
  MaxValue = High(Word);
  TestValues: array[0..6] of Word = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varWord);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsTypedArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsNumber, ElemValue, Format('element %d value type', [I]));
    CheckEquals(TestValues[I], Word(JsNumberToInt(ElemValue)), Format('element %d value', [I]));
  end;
end;

procedure TSimpleVarArrayToJs.TestIntegerArray;
const
  MinValue = Low(Integer);
  MaxValue = High(Integer);
  TestValues: array[0..6] of Integer = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varInteger);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsTypedArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsNumber, ElemValue, Format('element %d value type', [I]));
    CheckEquals(TestValues[I], JsNumberToInt(ElemValue), Format('element %d value', [I]));
  end;
end;

procedure TSimpleVarArrayToJs.TestLongWordArray;
const
  MinValue = Low(LongWord);
  MaxValue = High(LongWord);
  TestValues: array[0..6] of LongWord = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varLongWord);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsTypedArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsNumber, ElemValue, Format('element %d value type', [I]));
    CheckEquals(TestValues[I], LongWord(JsNumberToInt(ElemValue)), Format('element %d value', [I]));
  end;
end;

procedure TSimpleVarArrayToJs.TestBooleanArray;
var
  B: Boolean;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([0, 1], varBoolean);
  for B := Low(Boolean) to High(Boolean) do
    VarArrayPut(V, B, [Ord(B)]);

  Value := VariantToJsValue(V);
  CheckValueType(JsArray, Value, 'value type');

  for B := Low(B) to High(B) do
  begin
    ElemValue := JsArrayGetElement(Value, Ord(B));
    CheckValueType(JsBoolean, ElemValue, Format('element %d value type', [Ord(B)]));
    CheckEquals(B, JsBooleanToBoolean(ElemValue), Format('element %d value', [Ord(B)]));
  end;
end;

procedure TSimpleVarArrayToJs.TestSingleArray;
const
  TestValues: array[0..9] of Single = (NaN, Infinity, NegInfinity, 1.5e-45, -10100100.101, -42, 0, 42,
    20200200.202, 3.4e3);
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
  Expected, Actual: Extended;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varSingle);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsTypedArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsNumber, ElemValue, Format('element %d value type', [I]));
    Expected := TestValues[I];
    Actual := JsNumberToDouble(ElemValue);
    CheckEquals(Expected, Actual, Format('element %d value', [I]));
  end;
end;

procedure TSimpleVarArrayToJs.TestDoubleArray;
const
  TestValues: array[0..9] of Double = (NaN, Infinity, NegInfinity, 1.5e-45, -10100100.101, -42, 0, 42,
    20200200.202, 3.4e3);
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
  Expected, Actual: Extended;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varDouble);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsTypedArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsNumber, ElemValue, Format('element %d value type', [I]));
    Expected := TestValues[I];
    Actual := JsNumberToDouble(ElemValue);
    CheckEquals(Expected, Actual, Format('element %d value', [I]));
  end;
end;

procedure TSimpleVarArrayToJs.TestCurrencyArray;
const
  TestValues: array[0..6] of Currency = (-999999.99, -100000, -5389, 0, 42, 10234, 999999.99);
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
  Expected, Actual: Extended;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varCurrency);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsNumber, ElemValue, Format('element %d value type', [I]));
    Expected := TestValues[I];
    Actual := JsNumberToDouble(ElemValue);
    CheckEquals(Expected, Actual, Format('element %d value', [I]));
  end;
end;

procedure TSimpleVarArrayToJs.TestDateArray;
const
  TestValues: array[0..3] of TSystemTime = (
    (Year: 1970; Month:  1; Day:  1; Hour:  9; Minute: 30; Second: 25; MilliSecond: 300),
    (Year:  447; Month:  5; Day: 13; Hour: 23; Minute: 19; Second:  2; MilliSecond: 455),
    (Year: 2020; Month:  4; Day: 27; Hour: 19; Minute:  4; Second: 13; MilliSecond:  11),
    (Year: 2525; Month: 11; Day:  1; Hour:  3; Minute:  7; Second: 55; MilliSecond: 127)
  );
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varDate);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, SystemTimeToDateTime(TestValues[I]), [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsObject, ElemValue, Format('element %d value type', [I]));
    CheckTrue(JsInstanceOf(ElemValue, 'Date'), Format('element %d value instanceof Date', [I]));

    CheckEquals(TestValues[I].Year,        JsNumberToInt(JsCallFunction('getUTCFullYear',     [], ElemValue)), Format('element %d value getUTCFullYear',     [I]));
    CheckEquals(TestValues[I].Month - 1,   JsNumberToInt(JsCallFunction('getUTCMonth',        [], ElemValue)), Format('element %d value getUTCMonth',        [I]));
    CheckEquals(TestValues[I].Day,         JsNumberToInt(JsCallFunction('getUTCDate',         [], ElemValue)), Format('element %d value getUTCDate',         [I]));
    CheckEquals(TestValues[I].Hour,        JsNumberToInt(JsCallFunction('getUTCHours',        [], ElemValue)), Format('element %d value getUTCHours',        [I]));
    CheckEquals(TestValues[I].Minute,      JsNumberToInt(JsCallFunction('getUTCMinutes',      [], ElemValue)), Format('element %d value getUTCMinutes',      [I]));
    CheckEquals(TestValues[I].Second,      JsNumberToInt(JsCallFunction('getUTCSeconds',      [], ElemValue)), Format('element %d value getUTCSeconds',      [I]));
    CheckEquals(TestValues[I].MilliSecond, JsNumberToInt(JsCallFunction('getUTCMilliseconds', [], ElemValue)), Format('element %d value getUTCMilliseconds', [I]));
  end;
end;

(* TODO?
procedure TSimpleVarArrayToJs.TestStringArray;
const
  TestValues: array[0..6] of AnsiString = (
    'Hello, world!',
    'Hola món!',
    'Witaj świecie!',
    'Привет, мир!',
    'مرحبا بالعالم!',
    'ওহে বিশ্ব!',
    '你好，世界！'
  );
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varString);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsArray, Value);

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsString, ElemValue, 'value type');
    CheckEquals(TestValues[I], JsStringToUTF8String(ElemValue), 'value');
  end;
end;
*)

procedure TSimpleVarArrayToJs.TestOleStrArray;
const
  TestValues: array[0..6] of UnicodeString = (
    'Hello, world!',
    'Hola món!',
    'Witaj świecie!',
    'Привет, мир!',
    'مرحبا بالعالم!',
    'ওহে বিশ্ব!',
    '你好，世界！'
  );
var
  I: Integer;
  V: Variant;
  Value, ElemValue: JsValueRef;
begin
  V := VarArrayCreate([Low(TestValues), High(TestValues)], varOleStr);
  for I := Low(TestValues) to High(TestValues) do
    VarArrayPut(V, TestValues[I], [I]);

  Value := VariantToJsValue(V);
  CheckValueType(JsArray, Value, 'value type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    ElemValue := JsArrayGetElement(Value, I);
    CheckValueType(JsString, ElemValue, Format('element %d value type', [I]));
    CheckEquals(TestValues[I], JsStringToUnicodeString(ElemValue), Format('element %d value', [I]));
  end;
end;

{ TSimpleJsToVariant }

procedure TSimpleJsToVariant.TestUndefined;
var
  Value: JsValueRef;
  V: Variant;
begin
  Value := JsUndefinedValue;
  CheckValueType(JsUndefined, Value, 'value type');

  V := JsValueToVariant(Value);
  Check(VarIsEmpty(V), 'VarIsEmpty');
end;

procedure TSimpleJsToVariant.TestNull;
var
  Value: JsValueRef;
  V: Variant;
begin
  Value := JsNullValue;
  CheckValueType(JsNull, Value, 'value type');

  V := JsValueToVariant(Value);
  Check(VarIsNull(V), 'VarIsNull');
end;

procedure TSimpleJsToVariant.TestShortInt;
const
  MinValue = Low(ShortInt);
  MaxValue = High(ShortInt);
  TestValues: array[0..6] of ShortInt = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := IntToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(varShortInt, VarType(V), Format('vartype %d', [I]));
    CheckEquals(TestValues[I], ShortInt(V), Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestByte;
const
  MinValue = Low(Byte);
  MaxValue = High(Byte);
  TestValues: array[0..6] of Byte = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := IntToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));
    CheckEquals(TestValues[I], Byte(V), Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestSmallInt;
const
  MinValue = Low(SmallInt);
  MaxValue = High(SmallInt);
  TestValues: array[0..6] of SmallInt = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := IntToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));
    CheckEquals(TestValues[I], SmallInt(V), Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestWord;
const
  MinValue = Low(Word);
  MaxValue = High(Word);
  TestValues: array[0..6] of Word = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := IntToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));
    CheckEquals(TestValues[I], Word(V), Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestInteger;
const
  MinValue = Low(Integer);
  MaxValue = High(Integer);
  TestValues: array[0..6] of Integer = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := IntToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));
    CheckEquals(TestValues[I], Integer(V), Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestLongWord;
const
  MinValue = Low(LongWord);
  MaxValue = High(LongWord);
  TestValues: array[0..6] of LongWord = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := IntToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));
    CheckEquals(TestValues[I], LongWord(V), Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestInt64;
const
  MinValue = MIN_SAFE_INTEGER;
  MaxValue = MAX_SAFE_INTEGER;
  TestValues: array[0..6] of Int64 = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
  Expected, Actual: Extended;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := DoubleToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));

    Expected := TestValues[I];
    Actual := Double(V);
    CheckEquals(Expected, Actual, Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestUInt64;
const
  MaxValue = MAX_SAFE_INTEGER;
  TestValues: array[0..4] of UInt64 = (0, MaxValue div 4, MaxValue div 2, MaxValue div 2 + MaxValue div 4,
    UInt64(MaxValue));
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
  Expected, Actual: UInt64;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
   ChakraCoreCheck(JsConvertValueToNumber(StringToJsString(Format('%u', [TestValues[I]])), Value));
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));

    Expected := TestValues[I];
    Actual := Round(Double(V));
    CheckEquals(Int64(Expected), Int64(Actual), Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestBoolean;
var
  B: Boolean;
  Value: JsValueRef;
  V: Variant;
begin
  for B := Low(Boolean) to High(Boolean) do
  begin
    Value := BooleanToJsBoolean(B);
    V := JsValueToVariant(Value);
    CheckEquals(varBoolean, VarType(V), Format('vartype %s', [BoolToStr(B)]));
    CheckEquals(B, Boolean(V), Format('value %s', [BoolToStr(B)]));
  end;
end;

procedure TSimpleJsToVariant.TestSingle;
const
  TestValues: array[0..9] of Single = (NaN, Infinity, NegInfinity, 1.5e-45, -10100100.101, -42, 0, 42,
    20200200.202, 3.4e3);
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
  Expected, Actual: Extended;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := DoubleToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));

    Expected := TestValues[I];
    Actual := Single(V);
    CheckEquals(Expected, Actual, Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestDouble;
const
  TestValues: array[0..9] of Double = (NaN, Infinity, NegInfinity, 1.5e-45, -10100100.101, -42, 0, 42,
    20200200.202, 3.4e3);
var
  I: Integer;
  V: Variant;
  Value: JsValueRef;
  Expected, Actual: Extended;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := DoubleToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));

    Expected := TestValues[I];
    Actual := Double(V);
    CheckEquals(Expected, Actual, Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestCurrency;
const
  TestValues: array[0..6] of Currency = (-999999.99, -100000, -5389, 0, 42, 10234, 999999.99);
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
  Expected, Actual: Extended;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := DoubleToJsNumber(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(JsNumberVarType(Value), VarType(V), Format('vartype %d', [I]));

    Expected := TestValues[I];
    Actual := VarAsType(V, varCurrency);
    CheckEquals(Expected, Actual, Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestDate;
const
  TestValues: array[0..3] of TSystemTime = (
    (Year: 1970; Month:  1; Day:  1; Hour:  9; Minute: 30; Second: 25; MilliSecond: 300),
    (Year:  447; Month:  5; Day: 13; Hour: 23; Minute: 19; Second:  2; MilliSecond: 455),
    (Year: 2020; Month:  4; Day: 27; Hour: 19; Minute:  4; Second: 13; MilliSecond:  11),
    (Year: 2525; Month: 11; Day:  1; Hour:  3; Minute:  7; Second: 55; MilliSecond: 127)
  );
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
  Year, Month, Day, Hour, Minute, Second, MilliSecond: Word;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := DateTimeToJsDate(SystemTimeToDateTime(TestValues[I]));
    V := JsValueToVariant(Value);
    CheckEquals(varDate, VarType(V), Format('vartype %d', [I]));
    DecodeDate(TDateTime(V), Year, Month, Day);
    DecodeTime(TDateTime(V), Hour, Minute, Second, MilliSecond);

    CheckEquals(TestValues[I].Year,        Year,        Format('value %d year',        [I]));
    CheckEquals(TestValues[I].Month,       Month,       Format('value %d month',       [I]));
    CheckEquals(TestValues[I].Day,         Day,         Format('value %d day',         [I]));
    CheckEquals(TestValues[I].Hour,        Hour,        Format('value %d hour',        [I]));
    CheckEquals(TestValues[I].Minute,      Minute,      Format('value %d minute',      [I]));
    CheckEquals(TestValues[I].Second,      Second,      Format('value %d second',      [I]));
    CheckEquals(TestValues[I].MilliSecond, MilliSecond, Format('value %d millisecond', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestString;
const
  TestValues: array[0..6] of UnicodeString = (
    'Hello, world!',
    'Hola món!',
    'Witaj świecie!',
    'Привет, мир!',
    'مرحبا بالعالم!',
    'ওহে বিশ্ব!',
    '你好，世界！'
  );
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := StringToJsString(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(varOleStr, VarType(V), Format('vartype %d', [I]));

    CheckEquals(TestValues[I], JsStringToUnicodeString(Value), Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestOleStr;
const
  TestValues: array[0..6] of UnicodeString = (
    'Hello, world!',
    'Hola món!',
    'Witaj świecie!',
    'Привет, мир!',
    'مرحبا بالعالم!',
    'ওহে বিশ্ব!',
    '你好，世界！'
  );
var
  I: Integer;
  Value: JsValueRef;
  V: Variant;
begin
  for I := Low(TestValues) to High(TestValues) do
  begin
    Value := StringToJsString(TestValues[I]);
    V := JsValueToVariant(Value);
    CheckEquals(varOleStr, VarType(V), Format('vartype %d', [I]));

    CheckEquals(TestValues[I], JsStringToUnicodeString(Value), Format('value %d', [I]));
  end;
end;

procedure TSimpleJsToVariant.TestError;
var
  Value: JsValueRef;
  V: Variant;
begin
  // TODO
  Value := JsCreateError('error');
  V := JsValueToVariant(Value);
  CheckEquals(varError, VarType(V), 'vartype');
end;

{ TSimpleJsArrayToVariant }

procedure TSimpleJsArrayToVariant.TestShortIntArray;
const
  MinValue = Low(ShortInt);
  MaxValue = High(ShortInt);
  TestValues: array[0..6] of ShortInt = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
begin
  Value := JsCreateNativeTypedArray(JsArrayTypeInt8, Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, IntToJsNumber(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varShortInt, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varShortInt, VarType(E), Format('element %d vartype', [I]));
    CheckEquals(TestValues[I], ShortInt(E), Format('element %d value', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestByteArray;
const
  MinValue = Low(Byte);
  MaxValue = High(Byte);
  TestValues: array[0..6] of Byte = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
begin
  Value := JsCreateNativeTypedArray(JsArrayTypeUint8, Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, IntToJsNumber(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varByte, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varByte, VarType(E), Format('element %d vartype', [I]));
    CheckEquals(TestValues[I], Byte(E), Format('element %d value', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestSmallIntArray;
const
  MinValue = Low(SmallInt);
  MaxValue = High(SmallInt);
  TestValues: array[0..6] of SmallInt = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
begin
  Value := JsCreateNativeTypedArray(JsArrayTypeInt16, Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, IntToJsNumber(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varSmallInt, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varSmallInt, VarType(E), Format('element %d', [I]));
    CheckEquals(TestValues[I], SmallInt(E), Format('element %d value', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestWordArray;
const
  MinValue = Low(Word);
  MaxValue = High(Word);
  TestValues: array[0..6] of Word = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
begin
  Value := JsCreateNativeTypedArray(JsArrayTypeUint16, Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, IntToJsNumber(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varWord, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varWord, VarType(E), Format('element %d vartype', [I]));
    CheckEquals(TestValues[I], Word(E), Format('element %d value', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestIntegerArray;
const
  MinValue = Low(Integer);
  MaxValue = High(Integer);
  TestValues: array[0..6] of Integer = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
begin
  Value := JsCreateNativeTypedArray(JsArrayTypeInt32, Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, IntToJsNumber(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varInteger, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varInteger, VarType(E), Format('element %d vartype', [I]));
    CheckEquals(TestValues[I], Integer(E), Format('element %d value', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestLongWordArray;
const
  MinValue = Low(LongWord);
  MaxValue = High(LongWord);
  TestValues: array[0..6] of LongWord = (MinValue, MaxValue, 0, MinValue + MaxValue div 4, MinValue + MaxValue div 2,
    MaxValue - MaxValue div 2, MaxValue - MaxValue div 4);
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
begin
  Value := JsCreateNativeTypedArray(JsArrayTypeUInt32, Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, IntToJsNumber(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varLongWord, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varLongWord, VarType(E), Format('element %d vartype', [I]));
    CheckEquals(TestValues[I], Double(E), Format('element %d value', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestBooleanArray;
var
  B: Boolean;
  Value: JsValueRef;
  V, E: Variant;
begin
  Value := JsCreateArray(2);
  for B := Low(Boolean) to High(Boolean) do
    JsArraySetElement(Value, Ord(B), BooleanToJsBoolean(B));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varBoolean, VarType(V), 'array type');

  for B := Low(B) to High(B) do
  begin
    E := VarArrayGet(V, [Ord(B)]);
    CheckEquals(varBoolean, VarType(E), Format('element %d vartype', [Ord(B)]));
    CheckEquals(B, Boolean(E), Format('element %d value', [Ord(B)]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestSingleArray;
const
  TestValues: array[0..9] of Single = (NaN, Infinity, NegInfinity, 1.5e-45, -10100100.101, -42, 0, 42,
    20200200.202, 3.4e3);
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
  Expected, Actual: Extended;
begin
  Value := JsCreateNativeTypedArray(JsArrayTypeFloat32, Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, DoubleToJsNumber(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varSingle, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varSingle, VarType(E), Format('element %d vartype', [I]));
    Expected := TestValues[I];
    Actual := Single(E);
    CheckEquals(Expected, Actual, Format('element %d value', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestDoubleArray;
const
  TestValues: array[0..9] of Double = (NaN, Infinity, NegInfinity, 1.5e-45, -10100100.101, -42, 0, 42,
    20200200.202, 3.4e3);
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
  Expected, Actual: Extended;
begin
  Value := JsCreateNativeTypedArray(JsArrayTypeFloat64, Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, DoubleToJsNumber(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varDouble, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varDouble, VarType(E), Format('element %d vartype', [I]));
    Expected := TestValues[I];
    Actual := Double(E);
    CheckEquals(Expected, Actual, Format('element %d value', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestCurrencyArray;
const
  TestValues: array[0..6] of Currency = (-999999.99, -100000, -5389, 0, 42, 10234, 999999.99);
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
  Expected, Actual: Extended;
begin
  Value := JsCreateArray(Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, DoubleToJsNumber(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varDouble, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varDouble, VarType(E), Format('element %d vartype', [I]));
    Expected := TestValues[I];
    Actual := Currency(E);
    CheckEquals(Expected, Actual, Format('element %d value', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestDateArray;
const
  TestValues: array[0..3] of TSystemTime = (
    (Year: 1970; Month:  1; Day:  1; Hour:  9; Minute: 30; Second: 25; MilliSecond: 300),
    (Year:  447; Month:  5; Day: 13; Hour: 23; Minute: 19; Second:  2; MilliSecond: 455),
    (Year: 2020; Month:  4; Day: 27; Hour: 19; Minute:  4; Second: 13; MilliSecond:  11),
    (Year: 2525; Month: 11; Day:  1; Hour:  3; Minute:  7; Second: 55; MilliSecond: 127)
  );
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
  Year, Month, Day, Hour, Minute, Second, MilliSecond: Word;
begin
  Value := JsCreateArray(Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, DateTimeToJsDate(SystemTimeToDateTime(TestValues[I])));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varDate, VarType(V), 'array type');
  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varDate, VarType(E), Format('element %d vartype', [I]));
    DecodeDate(TDateTime(E), Year, Month, Day);
    DecodeTime(TDateTime(E), Hour, Minute, Second, MilliSecond);

    CheckEquals(TestValues[I].Year,        Year,        Format('value %d year',        [I]));
    CheckEquals(TestValues[I].Month,       Month,       Format('value %d month',       [I]));
    CheckEquals(TestValues[I].Day,         Day,         Format('value %d day',         [I]));
    CheckEquals(TestValues[I].Hour,        Hour,        Format('value %d hour',        [I]));
    CheckEquals(TestValues[I].Minute,      Minute,      Format('value %d minute',      [I]));
    CheckEquals(TestValues[I].Second,      Second,      Format('value %d second',      [I]));
    CheckEquals(TestValues[I].MilliSecond, MilliSecond, Format('value %d millisecond', [I]));
  end;
end;

procedure TSimpleJsArrayToVariant.TestOleStrArray;
const
  TestValues: array[0..6] of UnicodeString = (
    'Hello, world!',
    'Hola món!',
    'Witaj świecie!',
    'Привет, мир!',
    'مرحبا بالعالم!',
    'ওহে বিশ্ব!',
    '你好，世界！'
  );
var
  I: Integer;
  Value: JsValueRef;
  V, E: Variant;
begin
  Value := JsCreateArray(Length(TestValues));
  for I := Low(TestValues) to High(TestValues) do
    JsArraySetElement(Value, I, StringToJsString(TestValues[I]));

  V := JsValueToVariant(Value);
  Check(VarIsArray(V), 'is array');
  CheckEquals(1, VarArrayDimCount(V), 'array dimensions');
  CheckEquals(varArray or varOleStr, VarType(V), 'array type');

  for I := Low(TestValues) to High(TestValues) do
  begin
    E := VarArrayGet(V, [I]);
    CheckEquals(varOleStr, VarType(E), Format('element %d vartype', [I]));

    CheckEquals(TestValues[I], UnicodeString(E), Format('element %d value', [I]));
  end;
end;

{ TJsValueVariant }

procedure TJsValueVariant.Properties;
var
  Global, JSON, V: Variant;
  S: string;
  SystemTime: TSystemTime;
begin
  Global := JsValueVariant(JsGlobal);
  CheckEquals(varJsValue, VarType(Global), 'VarType(Global)');
  JSON := Global.JSON;
  CheckEquals(varJsValue, VarType(JSON), 'VarType(JSON)');

  Global.test1 := JsValueVariant(JsCreateObject);
  Global.test1.prop1 := Null;
  Global.test1.prop2 := 42;
  Global.test1.prop3 := 101.0101;
  Global.test1.prop4 := 'Hello, world!';
  Global.test1.prop5 := True;
  Global.test1.prop6 := JsValueVariant(JsCreateObject);
  Global.test1.prop7 := ComposeDateTime(EncodeDate(2020, 1, 5), EncodeTime(14, 42, 21, 137));
  Global.test1.prop8 := VarArrayOf([1, 2, 3, 4.5, 'abc']);

  CheckEquals(varJsValue, VarType(Global.test1), 'VarType(test1)');

  CheckEquals(varNull, VarType(Global.test1.prop1), 'VarType(test1.prop1)');

  CheckEquals(varShortInt, VarType(Global.test1.prop2), 'VarType(test1.prop2)');
  CheckEquals(42, Global.test1.prop2, 'test1.prop2');

  CheckEquals(varDouble, VarType(Global.test1.prop3), 'VarType(test1.prop3)');
  CheckEquals(101.0101, Global.test1.prop3, 'test1.prop3');

  CheckEquals(varOleStr, VarType(Global.test1.prop4), 'VarType(test1.prop4)');
  CheckEquals('Hello, world!', Global.test1.prop4, 'test1.prop4');

  CheckEquals(varBoolean, VarType(Global.test1.prop5), 'VarType(test1.prop5)');
  Check(Global.test1.prop5, 'test1.prop5');

  CheckEquals(varJsValue, VarType(Global.test1.prop6), 'VarType(test1.prop6)');

  CheckEquals(varDate, VarType(Global.test1.prop7), 'VarType(test1.prop7)');
  DecodeDate(Global.test1.prop7, SystemTime.Year, SystemTime.Month, SystemTime.Day);
  DecodeTime(Global.test1.prop7, SystemTime.Hour, SystemTime.Minute, SystemTime.Second, SystemTime.MilliSecond);
  CheckEquals(2020, SystemTime.Year,        'test1.prop7 year');
  CheckEquals(   1, Systemtime.Month,       'test1.prop7 month');
  CheckEquals(   5, SystemTime.Day,         'test1.prop7 day');
  CheckEquals(  14, Systemtime.Hour,        'test1.prop7 hour');
  CheckEquals(  42, SystemTime.Minute,      'test1.prop7 minute');
  CheckEquals(  21, SystemTime.Second,      'test1.prop7 second');
  CheckEquals( 137, SystemTime.Millisecond, 'test1.prop7 millisecond');

  CheckEquals(varArray or varVariant, VarType(Global.test1.prop8), 'VarType(test1.prop8)');

  CheckEquals(1,     Global.test1.prop8[0], 'test1.prop8 get element 0');
  CheckEquals(2,     Global.test1.prop8[1], 'test1.prop8 get element 1');
  CheckEquals(3,     Global.test1.prop8[2], 'test1.prop8 get element 2');
  CheckEquals(4.5,   Global.test1.prop8[3], 'test1.prop8 get element 3');
  CheckEquals('abc', Global.test1.prop8[4], 'test1.prop8 get element 4');

  V := Global.test1.prop8;
  CheckEquals(1, VarArrayDimCount(V),     'vararray dim count');
  CheckEquals(0, VarArrayLowBound(V, 1),  'vararray low bound');
  CheckEquals(4, VarArrayHighBound(V, 1), 'vararray high bound');
  Check(V[0] = Global.test1.prop8[0], 'vararray element 0 equals test1.prop8 get element 0');
  Check(V[1] = Global.test1.prop8[1], 'vararray element 1 equals test1.prop8 get element 1');
  Check(V[2] = Global.test1.prop8[2], 'vararray element 2 equals test1.prop8 get element 2');
  Check(V[3] = Global.test1.prop8[3], 'vararray element 3 equals test1.prop8 get element 3');
  Check(V[4] = Global.test1.prop8[4], 'vararray element 4 equals test1.prop8 get element 4');
  CheckEquals(1,     V[0], 'vararray element 0');
  CheckEquals(2,     V[1], 'vararray element 1');
  CheckEquals(3,     V[2], 'vararray element 2');
  CheckEquals(4.5,   V[3], 'vararray element 3');
  CheckEquals('abc', V[4], 'vararray element 4');

  Global.test1.prop8[0] := 100;
  Global.test1.prop8[1] := 200;
  Global.test1.prop8[2] := 300;
  Global.test1.prop8[3] := 450.77;
  Global.test1.prop8[4] := 'ABCDEF';

  CheckEquals(100,      Global.test1.prop8[0], 'test1.prop8 get element 0');
  CheckEquals(200,      Global.test1.prop8[1], 'test1.prop8 get element 1');
  CheckEquals(300,      Global.test1.prop8[2], 'test1.prop8 get element 2');
  CheckEquals(450.77,   Global.test1.prop8[3], 'test1.prop8 get element 3');
  CheckEquals('ABCDEF', Global.test1.prop8[4], 'test1.prop8 get element 4');

  V := Global.test1.prop8;
  CheckEquals(1, VarArrayDimCount(V),     'vararray dim count');
  CheckEquals(0, VarArrayLowBound(V, 1),  'vararray low bound');
  CheckEquals(4, VarArrayHighBound(V, 1), 'vararray high bound');
  Check(V[0] = Global.test1.prop8[0], 'vararray element 0 equals test1.prop8 get element 0');
  Check(V[1] = Global.test1.prop8[1], 'vararray element 1 equals test1.prop8 get element 1');
  Check(V[2] = Global.test1.prop8[2], 'vararray element 2 equals test1.prop8 get element 2');
  Check(V[3] = Global.test1.prop8[3], 'vararray element 3 equals test1.prop8 get element 3');
  Check(V[4] = Global.test1.prop8[4], 'vararray element 4 equals test1.prop8 get element 4');
  CheckEquals(100,      V[0], 'vararray element 0');
  CheckEquals(200,      V[1], 'vararray element 1');
  CheckEquals(300,      V[2], 'vararray element 2');
  CheckEquals(450.77,   V[3], 'vararray element 3');
  CheckEquals('ABCDEF', V[4], 'vararray element 4');

  S := JSON.stringify(Global);
  CheckEquals(
    '{' +
      '"test1":{' +
        '"prop1":null,' +
        '"prop2":42,' +
        '"prop3":101.0101,' +
        '"prop4":"Hello, world!",' +
        '"prop5":true,' +
        '"prop6":{},' +
        '"prop7":"2020-01-05T14:42:21.137Z",' +
        '"prop8":[100,200,300,450.77,"ABCDEF"]' +
      '}' +
    '}', S, 'JSON.stringify(Global)');

  Global.test2 := JSON.parse('{"prop9": 999.99, "prop10": 0}');

  CheckEquals(varJsValue, VarType(Global.test2), 'VarType(test2)');

  CheckEquals(varDouble, VarType(Global.test2.prop9), 'VarType(test2.prop9)');
  CheckEquals(999.99, Global.test2.prop9, 'test2.prop9');

  CheckEquals(varShortInt, VarType(Global.test2.prop10), 'VarType(test2.prop10)');
  CheckEquals(0, Global.test2.prop10, 'test2.prop10');

  S := JSON.stringify(Global);
  CheckEquals(
    '{' +
      '"test1":{' +
        '"prop1":null,' +
        '"prop2":42,' +
        '"prop3":101.0101,' +
        '"prop4":"Hello, world!",' +
        '"prop5":true,' +
        '"prop6":{},' +
        '"prop7":"2020-01-05T14:42:21.137Z",' +
        '"prop8":[100,200,300,450.77,"ABCDEF"]' +
      '},' +
      '"test2":{' +
        '"prop9":999.99,' +
        '"prop10":0' +
      '}' +
    '}', S, 'JSON.stringify(Globa)');

  // assign Null to property test2
  Global.test2 := Null;
  CheckEquals(varNull, VarType(Global.test2), 'VarType(test2)');

  // delete property test2
  Global.test2 := Unassigned;
  CheckEquals(varEmpty, VarType(Global.test2), 'VarType(test2)');

  // delete property test1
  JsDeleteProperty(JsGlobal, 'test1');
  CheckEquals(varEmpty, VarType(Global.test1), 'VarType(test1)');
end;

procedure TJsValueVariant.Functions;
var
  Global: Variant;
begin
  Global := JsValueVariant(JsGlobal);
  CheckEquals(varJsValue, VarType(Global), 'VarType(Global)');

  Global.func1 := JsValueVariant(JsRunScript('f1 = (a, b) => { return (a + b); }', ''));
  CheckEquals(varJsValue, VarType(Global.func1), 'VarType(func1)');
  CheckEquals('f1', Global.func1.name, 'func1.name');
  CheckEquals(25, Global.func1(7, 18), 'func1(7, 18)');

  JsRunScript('func2 = function f2(a, b) { return (a - b); }', '');
  CheckEquals(varJsValue, VarType(Global.func2), 'VarType(func2)');
  CheckEquals('f2', Global.func2.name, 'func2.name');
  CheckEquals(5, Global.func2(13, 8), 'func2(13, 8)');

  Global.func3 := JsValueVariant(JsRunScript('new Function(''a'', ''b'', ''return (a * b);'')', ''));
  CheckEquals(varJsValue, VarType(Global.func3), 'VarType(func3)');
  CheckEquals('anonymous', Global.func3.name, 'func3.name');
  CheckEquals(9, Global.func3(3, 3), 'func3(3, 3)');

  Global.func4 := JsValueVariant(JsRunScript('(function f4(a, b) { return (a / b); })', ''));
  CheckEquals(varJsValue, VarType(Global.func4), 'VarType(func4)');
  CheckEquals('f4', Global.func4.name, 'func4.name');
  CheckEquals(7, Global.func4(56, 8), 'func4(56, 8)');
end;

procedure TJsValueVariant.JsMath;
const
  Delta: Extended = 0.0000001;
  Expected_E: Extended = 2.71828182845905;
  Expected_LN2: Extended = 0.693147180559945;
  Expected_LN10: Extended = 2.30258509299405;
  TestValues: array[0..9] of Double = (NaN, NegInfinity, -1.0, -0.65, -0.1, 0.0, 0.15, 0.75, 1.0, Infinity);
var
  VMath: Variant;
  Expected, Actual: Extended;
  I: Integer;
begin
  VMath := JsValueVariant(JsGetProperty(JsGlobal, 'Math'));

  Actual := VMath.E;
  CheckEquals(Expected_E, Actual, Delta, 'Math.E');

  Actual := VMath.LN2;
  CheckEquals(Expected_LN2, Actual, Delta, 'Math.LN2');

  Actual := VMath.LN10;
  CheckEquals(Expected_LN10, Actual, Delta, 'Math.LN10');

  for I := Low(TestValues) to High(TestValues) do
  begin
    Expected := System.Abs(TestValues[I]);
    Actual := VMath.abs(TestValues[I]);
    CheckEquals(Expected, Actual, Delta, Format('Math.abs(%f)', [TestValues[I]]));

    Expected := Math.arccos(TestValues[I]);
    Actual := VMath.acos(TestValues[I]);
    CheckEquals(Expected, Actual, Delta, Format('Math.acos(%f)', [TestValues[I]]));

    Expected := Math.arcsin(TestValues[I]);
    Actual := VMath.asin(TestValues[I]);
    CheckEquals(Expected, Actual, Delta, Format('Math.asin(%f)', [TestValues[I]]));
  end;
end;

initialization

{$ifdef FPC}
  RegisterTest('ChakraCoreVarUtils', TTestSuite.Create(TSimpleVariantToJs,      'Variant to Javascript'));
  RegisterTest('ChakraCoreVarUtils', TTestSuite.Create(TSimpleVarArrayToJs,     'Variant array to Javascript'));
  RegisterTest('ChakraCoreVarUtils', TTestSuite.Create(TSimpleJsToVariant,      'Javascript to Variant'));
  RegisterTest('ChakraCoreVarUtils', TTestSuite.Create(TSimpleJsArrayToVariant, 'Javascript array to Variant'));
  RegisterTest('ChakraCoreVarUtils', TTestSuite.Create(TJsValueVariant,         'JsValueVariant'));
{$else}
  RegisterTest('ChakraCoreVarUtils', TSimpleVariantToJs.Suite('Variant to Javascript'));
  RegisterTest('ChakraCoreVarUtils', TSimpleVarArrayToJs.Suite('Variant array to Javascript'));
  RegisterTest('ChakraCoreVarUtils', TSimpleJsToVariant.Suite('Javascript to Variant'));
  RegisterTest('ChakraCoreVarUtils', TSimpleJsArrayToVariant.Suite('Javascript array to Variant'));
  RegisterTest('ChakraCoreVarUtils', TJsValueVariant.Suite('JsValueVariant'));
{$endif}

end.
