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

unit Test_ChakraCore;

interface

{$include ..\src\common.inc}

uses
  Classes, SysUtils,
{$ifdef FPC}
{$ifndef WINDOWS}
  cwstring,
{$endif}
  fpcunit, testutils, testregistry,
{$else}
  TestFramework,
{$endif}
  Compat, ChakraCoreVersion, ChakraCommon, ChakraCore, ChakraCoreUtils;

type
  TBaseTestCase = class(TTestCase)
  public
{$ifdef DELPHI}
    // work around Delphi 2007 and earlier compiler error "Ambiguous overloaded call to 'CheckEquals'"
    procedure CheckEquals(expected, actual: Integer; msg: string = ''); override;
    // DUnit needs a delta when comparing float values
    procedure CheckEquals(expected, actual: extended; msg: string = ''); reintroduce; overload;
{$endif}
    procedure CheckEquals(expected, actual: JsValueType; const msg: string = ''); overload;
    procedure CheckEquals(expected, actual: JsTypedArrayType; const msg: string = ''); overload;
    procedure CheckValueType(expected: JsValueType; value: JsValueRef; const msg: string = '');
  end;

  TChakraCoreTestCase = class(TBaseTestCase)
  private
    FContext: JsContextRef;
    FRuntime: JsRuntimeHandle;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  end;

  TChakraCoreUtilsScripting = class(TChakraCoreTestCase)
  published
    procedure TestVersion;
    procedure TestUndefined;
    procedure TestNull;
    procedure TestInt;
    procedure TestDouble;
    procedure TestInfinity;
    procedure TestNaN;
    procedure TestString;
    procedure TestStringUnicode;
    procedure TestBoolean;
    procedure TestObject;
    procedure TestFunction;
    procedure TestError;
    procedure TestArray;
    procedure TestSymbol;
    procedure TestArrayBuffer;
    procedure TestTypedArray;
    procedure TestDataView;
    procedure TestThrowBoolean;
    procedure TestThrowInt;
    procedure TestThrowString;
    procedure TestThrowObject;
    procedure TestThrowError;
    procedure TestThrowHostError;
    procedure TestCallFunction01;
    procedure TestCallFunction02;
    procedure TestCallFunctions;
    procedure TestCallNew;
    procedure TestFPExceptions;
  end;

implementation

uses
  Math;

{$ifdef DELPHI}
procedure TBaseTestCase.CheckEquals(expected, actual: Integer; msg: string);
begin
  inherited CheckEquals(expected, actual, msg);
end;

procedure TBaseTestCase.CheckEquals(expected, actual: extended; msg: string);
const
  DefaultDelta = 0.0000001;
begin
  inherited CheckEquals(expected, actual, DefaultDelta, msg);
end;
{$endif}

procedure TBaseTestCase.CheckEquals(expected, actual: JsValueType; const msg: string);
begin
  inherited CheckEquals(Ord(expected), Ord(actual), msg);
end;

procedure TBaseTestCase.CheckEquals(expected, actual: JsTypedArrayType; const msg: string);
begin
  inherited CheckEquals(Ord(expected), Ord(actual), msg);
end;

procedure TBaseTestCase.CheckValueType(expected: JsValueType; value: JsValueRef; const msg: string);
begin
  CheckEquals(expected, JsGetValueType(Value), msg);
end;

procedure TChakraCoreTestCase.SetUp;
begin
  FRuntime := nil;
  FContext := nil;

  ChakraCoreCheck(JsCreateRuntime(JsRuntimeAttributeNone, nil, FRuntime));
  ChakraCoreCheck(JsCreateContext(FRuntime, FContext));
  ChakraCoreCheck(JsSetCurrentContext(FContext));
end;

procedure TChakraCoreTestCase.TearDown;
begin
  ChakraCoreCheck(JsSetCurrentContext(JS_INVALID_REFERENCE));
  if Assigned(FRuntime) then
    ChakraCoreCheck(JsDisposeRuntime(FRuntime));
end;

procedure TChakraCoreUtilsScripting.TestVersion;
begin
  CheckEquals(Integer(1), CHAKRA_CORE_MAJOR_VERSION, 'major version number');
  CheckEquals(Integer(11), CHAKRA_CORE_MINOR_VERSION, 'minor version number');
  CheckEquals(Integer(2), CHAKRA_CORE_PATCH_VERSION, 'patch version number');
end;

procedure TChakraCoreUtilsScripting.TestUndefined;
const
  SScript = 'this.result = undefined';
  SName = 'TestUndefined.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsUndefined, Result, 'result type');
  end;
end;

procedure TChakraCoreUtilsScripting.TestNull;
const
  SScript = 'this.result = null';
  SName = 'TestNull.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsNull, Result, 'result type');
  end;
end;

procedure TChakraCoreUtilsScripting.TestInt;
const
  IntValue = 42;
  SScript = 'this.result = %d';
  SName = 'TestInt.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(Format(SScript, [IntValue])), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(Format(SScript, [IntValue])), UTF8String(SName));

    CheckValueType(JsNumber, Result, 'result type');
    CheckEquals(IntValue, JsNumberToInt(Result), 'result value');
  end;
end;

procedure TChakraCoreUtilsScripting.TestDouble;
const
  DoubleValue: Double = 3.14;
  SScript = 'this.result = %f';
  SName = 'TestDouble.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False To True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(Format(SScript, [DoubleValue], DefaultFormatSettings)), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(Format(SScript, [DoubleValue], DefaultFormatSettings)), UTF8String(SName));

    CheckValueType(JsNumber, Result, 'result type');
    CheckEquals(DoubleValue, JsNumberToDouble(Result), 'result value');
  end;
end;

procedure TChakraCoreUtilsScripting.TestInfinity;
const
  SScript = 'this.result = Infinity';
  SName = 'TestInfinity.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsNumber, Result, 'result type');
    Check(IsInfinite(JsNumberToDouble(Result)), 'INF');
  end;
end;

procedure TChakraCoreUtilsScripting.TestNaN;
const
  SScript = 'this.result = NaN';
  SName = 'TestNaN.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsNumber, Result, 'result type');
    Check(IsNan(JsNumberToDouble(Result)), 'NaN');
  end;
end;

procedure TChakraCoreUtilsScripting.TestString;
const
  StringValue: UnicodeString = 'Hello, world!';
  SScript = 'this.result = "%s"';
  SName = 'TestString.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(Format(SScript, [StringValue])), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(Format(SScript, [StringValue])), UTF8String(SName));

    CheckValueType(JsString, Result, 'result type');
    CheckEquals(StringValue, JsStringToUnicodeString(Result), 'result value');
  end;
end;

procedure TChakraCoreUtilsScripting.TestStringUnicode;
const
  StringValue: array [0..6] of AnsiChar = (#$E4, #$BD, #$A0, #$E5, #$A5, #$BD, #$00);
  SScript = 'this.result = "%s"';
  SName = 'TestString.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(WideFormat(SScript, [UTF8ToString(StringValue)]), UnicodeString(SName))
    else
      Result := JsRunScript(Format(SScript, [UTF8String(StringValue)]), UTF8String(SName));

    CheckValueType(JsString, Result, 'result type');
{$ifdef SUPPORTS_UNICODE}
    CheckEquals(UTF8ToString(StringValue), JsStringToUnicodeString(Result), 'result value');
{$else}
    CheckEquals(UTF8String(StringValue), JsStringToUTF8String(Result), 'result value');
{$endif}
  end;
end;

procedure TChakraCoreUtilsScripting.TestBoolean;
const
  SScripts: array[Boolean] of string = (
    'this.result = false',
    'this.result = true'
  );
  SName = 'TestBoolean.js';
var
  Unicode, BooleanValue: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    for BooleanValue := False to True do
    begin
      if Unicode then
        Result := JsRunScript(UnicodeString(SScripts[BooleanValue]), UnicodeString(SName))
      else
        Result := JsRunScript(UTF8String(SScripts[BooleanValue]), UTF8String(SName));

      CheckValueType(JsBoolean, Result, 'result type');
      CheckEquals(BooleanValue, JsBooleanToBoolean(Result), 'result value');
    end;
  end;
end;

procedure TChakraCoreUtilsScripting.TestObject;
const
  SScript = 'this.result = this';
  SName = 'TestObject.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsObject, Result, 'result type');
  end;
end;

procedure TChakraCoreUtilsScripting.TestFunction;
const
  SScript = 'this.result = function() { return 42; }';
  SName = 'TestFunction.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsFunction, Result, 'result type');
  end;
end;

procedure TChakraCoreUtilsScripting.TestError;
const
  SScript = 'this.result = new Error("Test Error")';
  SName = 'TestError.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsError, Result, 'result type');
  end;
end;

procedure TChakraCoreUtilsScripting.TestArray;
const
  IntElementValue = 42;
  DoubleElementValue = 3.14;
  StringElementValue: UnicodeString = 'Hello, world!';
  SScript = 'this.result = [undefined, null, %d, %f, "%s", true, false, this, function() { return 42; }, new Error("Test Error")]';
  SName = 'TestArray.js';
var
  Unicode: Boolean;
  Result, Element: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(Format(SScript, [IntElementValue, DoubleElementValue, StringElementValue],
        DefaultFormatSettings)), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(Format(SScript, [IntElementValue, DoubleElementValue, StringElementValue],
        DefaultFormatSettings)), UTF8String(SName));

    CheckValueType(JsArray, Result, 'result type');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(0), Element));
    CheckValueType(JsUndefined, Element, 'element 0 type');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(1), Element));
    CheckValueType(JsNull, Element, 'element 1 type');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(2), Element));
    CheckValueType(JsNumber, Element, 'element 2 type');
    CheckEquals(IntElementValue, JsNumberToInt(Element), 'element 2 value');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(3), Element));
    CheckValueType(JsNumber, Element, 'element 3 type');
    CheckEquals(DoubleElementValue, JsNumberToDouble(Element), 'element 3 value');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(4), Element));
    CheckValueType(JsString, Element, 'element 4 type');
    CheckEquals(StringElementValue, JsStringToUnicodeString(Element), 'element 4 value');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(5), Element));
    CheckValueType(JsBoolean, Element, 'element 5 type');
    CheckEquals(True, JsBooleanToBoolean(Element), 'element 5 value');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(6), Element));
    CheckValueType(JsBoolean, Element, 'element 6 type');
    CheckEquals(False, JsBooleanToBoolean(Element), 'element 6 value');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(7), Element));
    CheckValueType(JsObject, Element, 'element 7 type');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(8), Element));
    CheckValueType(JsFunction, Element, 'element 8 type');

    ChakraCoreCheck(JsGetIndexedProperty(Result, IntToJsNumber(9), Element));
    CheckValueType(JsError, Element, 'element 9 type');
  end;
end;

procedure TChakraCoreUtilsScripting.TestSymbol;
const
  SScript = 'this.result = Symbol(''foo'')';
  SName = 'TestSymbol.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsSymbol, Result, 'result type');
  end;
end;

procedure TChakraCoreUtilsScripting.TestArrayBuffer;
const
  SScript = 'this.result = new ArrayBuffer(1024)';
  SName = 'TestArrayBuffer.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsArrayBuffer, Result, 'result type');
  end;
end;

procedure TChakraCoreUtilsScripting.TestTypedArray;
const
  SScripts: array[JsTypedArrayType] of string = (
    'this.result = new Int8Array(16)',
    'this.result = new Uint8Array(16)',
    'this.result = new Uint8ClampedArray(16)',
    'this.result = new Int16Array(16)',
    'this.result = new Uint16Array(16)',
    'this.result = new Int32Array(16)',
    'this.result = new Uint32Array(16)',
    'this.result = new Float32Array(16)',
    'this.result = new Float64Array(16)'
  );
  SName = 'TesTypedtArray.js';
var
  Unicode: Boolean;
  I: JsTypedArrayType;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    for I := Low(JsTypedArraytype) to High(JsTypedArraytype) do
    begin
      if Unicode then
        Result := JsRunScript(UnicodeString(SScripts[I]), UnicodeString(SName))
      else
        Result := JsRunScript(UTF8String(SScripts[I]), UTF8String(SName));

      CheckValueType(JsTypedArray, Result, 'result type');
      CheckEquals(I, JsGetTypedArrayType(Result), 'element type');
    end;
  end;
end;

procedure TChakraCoreUtilsScripting.TestDataView;
const
  SScript = 'this.result = new DataView(new ArrayBuffer(1024), 0, 1024)';
  SName = 'TestArrayBuffer.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsDataView, Result, 'result type');
  end;
end;

procedure TChakraCoreUtilsScripting.TestThrowBoolean;
const
  SScript = 'throw true;';
  SName = 'TestThrowBoolean.js';
var
  Unicode: Boolean;
begin
  for Unicode := False to True do
  begin
    try
      if Unicode then
        JsRunScript(UnicodeString(SScript), UnicodeString(SName))
      else
        JsRunScript(UTF8String(SScript), UTF8String(SName));

      Check(False, 'Expected error');
    except
      on E: EChakraCore do
      begin
        CheckValueType(JsBoolean, E.Error, 'error type');
        CheckEquals(True, JsBooleanToBoolean(E.Error), 'error value');
      end;
    end;
  end;
end;

procedure TChakraCoreUtilsScripting.TestThrowInt;
const
  IntValue = 42;
  SScript = 'throw %d;';
  SName = 'TestThrowInt.js';
var
  Unicode: Boolean;
begin
  for Unicode := False to True do
  begin
    try
      if Unicode then
        JsRunScript(UnicodeString(Format(SScript, [IntValue])), UnicodeString(SName))
      else
        JsRunScript(UTF8String(Format(SScript, [IntValue])), UTF8String(SName));

      Check(False, 'Expected error');
    except
      on E: EChakraCore do
      begin
        CheckValuetype(JsNumber, E.Error, 'error type');
        CheckEquals(IntValue, JsNumberToInt(E.Error), 'error value');
      end;
    end;
  end;
end;

procedure TChakraCoreUtilsScripting.TestThrowString;
const
  StringValue: UnicodeString = 'Error';
  SScript = 'throw "%s";';
  SName = 'TestThrowString.js';
var
  Unicode: Boolean;
begin
  for Unicode := False to True do
  begin
    try
      if Unicode then
        JsRunScript(UnicodeString(Format(SScript, [StringValue])), UnicodeString(SName))
      else
        JsRunScript(UTF8String(Format(SScript, [StringValue])), UTF8String(SName));

      Check(False, 'Expected error');
    except
      on E: EChakraCore do
      begin
        CheckValueType(JsString, E.Error, 'error type');
        CheckEquals(StringValue, JsStringToUnicodeString(E.Error));
      end;
    end;
  end;
end;

procedure TChakraCoreUtilsScripting.TestThrowObject;
const
  SScript = 'throw this;';
  SName = 'TestThrowObject.js';
var
  Unicode: Boolean;
begin
  for Unicode := False to True do
  begin
    try
      if Unicode then
        JsRunScript(UnicodeString(SScript), UnicodeString(SName))
      else
        JsRunScript(UTF8String(SScript), UTF8String(SName));

      Check(False, 'Expected error');
    except
      on E: EChakraCore do
      begin
        CheckValueType(JsObject, E.Error, 'error type');
      end;
    end;
  end;
end;

procedure TChakraCoreUtilsScripting.TestThrowError;
const
  SScript = 'syntax error?';
  SName = 'TestThrowError.js';
var
  Unicode: Boolean;
  Name, Message: JsValueRef;
begin
  for Unicode := False to True do
  begin
    try
      if Unicode then
        JsRunScript(UnicodeString(SScript), UnicodeString(SName))
      else
        JsRunScript(UTF8String(SScript), UTF8String(SName));

      Check(False, 'Expected error');
    except
      on E: EChakraCore do
      begin
        CheckValueType(JsError, E.Error, 'error type');

        Name := JsGetProperty(E.Error, 'name');
        Message := JsGetProperty(E.Error, 'message');

        CheckEquals('SyntaxError', JsStringToUnicodeString(Name));
        CheckEquals('Expected '';''', JsStringToUnicodeString(Message));
      end;
    end;
  end;
end;

const
  ErrorTypeNames: array[TErrorType] of string = ('Error', 'RangeError', 'ReferenceError', 'SyntaxError', 'TypeError', 'URIError');

type
  PErrorType = ^TErrorType;

function TestErrorCallback(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRef; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
var
  ErrorType: PErrorType absolute CallbackState;
begin
  ChakraCoreCheck(JsGetUndefinedValue(Result));
  JsThrowError(Format('Test %s error', [ErrorTypeNames[ErrorType^]]), ErrorType^);
end;

procedure TChakraCoreUtilsScripting.TestThrowHostError;
const
  SScript = 'this.testerror();';
  SName = 'TestThrowHostError.js';
var
  Global: JsValueRef;
  Unicode: Boolean;
  EType: TErrorType;
  Name, Message: JsValueRef;
begin
  ChakraCoreCheck(JsGetGlobalObject(Global));
  JsSetCallback(Global, 'testerror', @TestErrorCallback, @EType);
  for Unicode := False to True do
  begin
    for EType := Low(TErrorType) to High(TErrorType) do
    begin
      try
        if Unicode then
          JsRunScript(UnicodeString(SScript), UnicodeString(SName))
        else
          JsRunScript(UTF8String(SScript), UTF8String(SName));

        Check(False, 'Expected error');
      except
        on E: EChakraCore do
        begin
          CheckValueType(JsError, E.Error, 'error type');

          Name := JsGetProperty(E.Error, 'name');
          Message := JsGetProperty(E.Error, 'message');

          CheckEquals(ErrorTypeNames[EType], JsStringToUnicodeString(Name));
          CheckEquals(Format('Test %s error', [ErrorTypeNames[EType]]), JsStringToUnicodeString(Message));
        end;
      end;
    end;
  end;
end;

procedure TChakraCoreUtilsScripting.TestCallFunction01;
const
  SScript = 'function square(number) { return number * number; }';
  SName = 'TestCallFunction01.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
  Global, SquareFunc: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      JsRunScript(UTF8String(SScript), UTF8String(SName));

    ChakraCoreCheck(JsGetGlobalObject(Global));
    SquareFunc := JsGetProperty(Global, 'square');
    Result := JsCallFunction(SquareFunc, [Global, IntToJsNumber(3)]);

    CheckValueType(JsNumber, Result, 'result type');
    CheckEquals(9, JsNumberToInt(Result), 'result value');
  end;
end;

procedure TChakraCoreUtilsScripting.TestCallFunction02;
const
  SScript = 'function square(number) { return number * number; }';
  SName = 'TestCallFunction02.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      JsRunScript(UTF8String(SScript), UTF8String(SName));

    Result := JsCallFunction('square', [IntToJsNumber(3)]);

    CheckValueType(JsNumber, Result, 'result type');
    CheckEquals(9, JsNumberToInt(Result), 'result value');
  end;
end;

procedure TChakraCoreUtilsScripting.TestCallFunctions;
const
  SScript1 = 'function square(number) { return number * number; }';
  SScript2 = 'function fact(number) { if (number == 0) { return 1; } else { return number * fact(number - 1); } }';
  SName = 'TestCallFunctions.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
    begin
      Result := JsRunScript(UnicodeString(SScript1), UnicodeString(SName));
      CheckValueType(JsUndefined, Result, 'result type');
      Result := JsRunScript(UnicodeString(SScript2), UnicodeString(SName));
      CheckValueType(JsUndefined, Result, 'result type');
    end
    else
    begin
      Result := JsRunScript(UTF8String(SScript1), UTF8String(SName));
      CheckValueType(JsUndefined, Result, 'result type');
      Result := JsRunScript(UTF8String(SScript2), UTF8String(SName));
      CheckValueType(JsUndefined, Result, 'result type');
    end;

    Result := JsCallFunction('square', [IntToJsNumber(3)]);

    CheckValuetype(JsNumber, Result, 'result type');
    CheckEquals(9, JsNumberToInt(Result), 'result value');

    Result := JsCallFunction('fact', [IntToJsNumber(5)]);

    CheckValueType(JsNumber, Result, 'result type');
    CheckEquals(120, JsNumberToInt(Result), 'result value');
  end;
end;

procedure TChakraCoreUtilsScripting.TestCallNew;
const
  SScript = 'this.result = new Object()';
  SName = 'TestCallNew.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsObject, Result, 'result type');
    Check(JsInstanceOf(Result, 'Object'), 'instanceof Object');
  end;
end;

procedure TChakraCoreUtilsScripting.TestFPExceptions;
const
  SScript = 'var d = new Date(); this.Result = d.getTime();';
  SName = 'TestFPExceptions.js';
var
  Unicode: Boolean;
  Result: JsValueRef;
begin
  for Unicode := False to True do
  begin
    if Unicode then
      Result := JsRunScript(UnicodeString(SScript), UnicodeString(SName))
    else
      Result := JsRunScript(UTF8String(SScript), UTF8String(SName));

    CheckValueType(JsNumber, Result, 'result type');
  end;
end;

initialization
{$ifdef FPC}
  RegisterTest(TChakraCoreUtilsScripting);
{$else}
  RegisterTest(TChakraCoreUtilsScripting.Suite);
{$endif}

end.
