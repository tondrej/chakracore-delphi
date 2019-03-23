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

unit Test_Classes;

interface

{$include ..\src\common.inc}

uses
  Classes, SysUtils,
{$ifdef FPC}
{$ifndef WINDOWS}
  cwstring,
{$endif}
  fpcunit, testregistry,
{$else}
  TestFramework,
{$endif}
  Compat, ChakraCommon, ChakraCore, ChakraCoreUtils, ChakraCoreClasses,
  Test_ChakraCore;

type

  { TChakraCoreContextTestCase }

  TChakraCoreContextTestCase = class(TBaseTestCase)
  published
    procedure TestScriptReferenceError;
    procedure TestScriptSyntaxError;
    procedure TestEvalReferenceError;
    procedure TestEvalSyntaxError;
  end;

  { TNativeClassTestCase }

  TNativeClassTestCase = class(TBaseTestCase)
  published
    procedure TestMethod1AsScript;
    procedure TestMethod1AsFunction;
    procedure TestNamedProperty;
    procedure TestProjectedClass;
    procedure TestClassProjectedTwice;
    procedure TestClassProjectedInMultipleContexts;
    procedure TestInheritance;
    procedure TestInheritance2;
    procedure TestFinalizer;
    procedure TestFinalizer2;
    procedure TestFinalizer3;
    procedure TestFinalizer4;
  end;

implementation

{ TChakraCoreContextTestCase }

procedure TChakraCoreContextTestCase.TestScriptReferenceError;
const
  SScript = 'badref.bla();';
  SName = 'TestScriptReferenceError.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    try
      Context.RunScript(SScript, SName);
    except
      on E: EChakraCoreScript do
      begin
        CheckEquals(0, E.Line, 'EChakraCoreScript.Line');
        CheckEquals(0, E.Column, 'EChakraCoreScript.Column');
        CheckEquals(UnicodeString(SScript), E.Source, 'EChakraCoreScript.Source');
        CheckEquals(UnicodeString(SName), E.ScriptURL, 'EChakraCoreScript.ScriptURL');
        CheckEquals(LoadResString(JsGetErrorMessage(JsErrorScriptException)) + sLineBreak +
          'ReferenceError: ''badref'' is not defined', E.Message, 'EChakraCoreScript.Message');
      end;
    end;
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

procedure TChakraCoreContextTestCase.TestScriptSyntaxError;
const
  SScript: array[0..1] of UnicodeString = (
    '// first line comment',
    '   @ bad syntax'
  );
  SName = 'TestScriptSyntaxError.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    try
      Context.RunScript(SScript[0] + UnicodeString(sLineBreak) + SScript[1], UnicodeString(SName));
    except
      on E: EChakraCoreScript do
      begin
        CheckEquals(1, E.Line, 'EChakraCoreScript.Line');
        CheckEquals(3, E.Column, 'EChakraCoreScript.Column');
        CheckEquals(SScript[1], E.Source, 'EChakraCoreScript.Source');
        CheckEquals(UnicodeString(SName), E.ScriptURL, 'EChakraCoreScript.ScriptURL');
        CheckEquals(LoadResString(JsGetErrorMessage(JsErrorScriptCompile)) + sLineBreak +
          'SyntaxError: Invalid character', E.Message, 'EChakraCoreScript.Message');
      end;
    end;
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

procedure TChakraCoreContextTestCase.TestEvalReferenceError;
const
  SScript = 'badref.bla();';
  SName = 'TestEvalReferenceError.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    try
      Context.RunScript('eval(''' + SScript + ''');', SName);
    except
      on E: EChakraCoreScript do
      begin
        CheckEquals(0, E.Line, 'EChakraCoreScript.Line');
        CheckEquals(0, E.Column, 'EChakraCoreScript.Column');
        CheckEquals(UnicodeString(SScript), E.Source, 'EChakraCoreScript.Source');
        CheckEquals(UnicodeString('eval code'), E.ScriptURL, 'EChakraCoreScript.ScriptURL');
        CheckEquals(LoadResString(JsGetErrorMessage(JsErrorScriptException)) + sLineBreak +
          'ReferenceError: ''badref'' is not defined', E.Message, 'EChakraCoreScript.Message');
      end;
    end;
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

procedure TChakraCoreContextTestCase.TestEvalSyntaxError;
const
  SScript = 'eval(''@ bad syntax'');';
  SName = 'TestEvalSyntaxError.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    try
      Context.RunScript(SScript, SName);
    except
      on E: EChakraCoreScript do
      begin
        CheckEquals(0, E.Line, 'EChakraCoreScript.Line');
        CheckEquals(0, E.Column, 'EChakraCoreScript.Column');
        CheckEquals(UnicodeString(SScript), E.Source, 'EChakraCoreScript.Source');
        CheckEquals(UnicodeString(SName), E.ScriptURL, 'EChakraCoreScript.ScriptURL');
        CheckEquals(LoadResString(JsGetErrorMessage(JsErrorScriptException)) + sLineBreak +
          'SyntaxError: Invalid character', E.Message, 'EChakraCoreScript.Message');
      end;
    end;
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

{ TTestObject1 }

type
  TTestObject1 = class(TNativeObject)
  private
    FMethod1Called: Boolean;
    FProp1: UnicodeString;

    function GetProp1: JsValueRef;
    procedure SetProp1(Value: JsValueRef);
    function Method1(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    class procedure RegisterProperties(AInstance: JsHandle); override;
    class procedure RegisterMethods(AInstance: JsHandle); override;
  end;

function TTestObject1.GetProp1: JsValueRef;
begin
  Result := StringToJsString(FProp1);
end;

procedure TTestObject1.SetProp1(Value: JsValueRef);
var
  SValue: UnicodeString;
begin
  SValue := JsStringToUnicodeString(Value);
  if SValue <> FProp1 then
  begin
    // Prop1 changed
    FProp1 := SValue;
  end;
end;

function TTestObject1.Method1(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := StringToJsString('Hello');
  FMethod1Called := True;
end;

class procedure TTestObject1.RegisterMethods(AInstance: JsHandle);
begin
  RegisterMethod(AInstance, 'method1', @TTestObject1.Method1);
end;

class procedure TTestObject1.RegisterProperties(AInstance: JsHandle);
begin
  RegisterNamedProperty(AInstance, 'prop1', False, False, @TTestObject1.GetProp1, @TTestObject1.SetProp1);
end;

{ TNativeClassTestCase }

procedure TNativeClassTestCase.TestMethod1AsScript;
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
  TestObject: TTestObject1;
  Result: JsValueRef;
begin
  Runtime := nil;
  Context := nil;
  TestObject := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TestObject := TTestObject1.Create;
    JsSetProperty(Context.Global, 'obj', TestObject.Instance);
    Result := Context.RunScript('obj.method1(null, null);', 'TestMethod1.js');
    Check(TestObject.FMethod1Called, 'method1 called');
    CheckValueType(JsString, Result, 'method1 result type');
    CheckEquals(UnicodeString('Hello'), JsStringToUnicodeString(Result), 'method1 result');
  finally
    TestObject.Free;
    Context.Free;
    Runtime.Free;
  end;
end;

procedure TNativeClassTestCase.TestMethod1AsFunction;
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
  TestObject: TTestObject1;
  Result: JsValueRef;
begin
  Runtime := nil;
  Context := nil;
  TestObject := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TestObject := TTestObject1.Create;
    JsSetProperty(Context.Global, 'obj', TestObject.Instance);
    Result := Context.CallFunction('method1', [], TestObject.Instance);
    Check(TestObject.FMethod1Called, 'method1 called');
    CheckValueType(JsString, Result, 'method1 result type');
    CheckEquals(UnicodeString('Hello'), JsStringToUnicodeString(Result), 'method1 result');
  finally
    TestObject.Free;
    Context.Free;
    Runtime.Free;
  end;
end;

procedure TNativeClassTestCase.TestNamedProperty;
const
  SValue: UnicodeString = 'Hello';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
  TestObject: TTestObject1;
begin
  Runtime := nil;
  Context := nil;
  TestObject := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TestObject := TTestObject1.Create;
    JsSetProperty(Context.Global, 'obj', TestObject.Instance);
    Context.RunScript(WideFormat('obj.prop1 = ''%s'';', [SValue]), UnicodeString('TestNamedProperty.js'));
    CheckEquals(SValue, TestObject.FProp1, 'prop1 value');
    CheckEquals(SValue, JsStringToUnicodeString(JsGetProperty(TestObject.Instance, 'prop1')), 'prop1 value');
  finally
    TestObject.Free;
    Context.Free;
    Runtime.Free;
  end;
end;

procedure TNativeClassTestCase.TestProjectedClass;
const
  SScript: UnicodeString = 'var obj = new TestObject(); var s1 = obj.method1(); obj.prop1 = s1; var s2 = obj.prop1;';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TTestObject1.Project('TestObject');
    Context.RunScript(SScript, UnicodeString('TestProjectedClass.js'));
    CheckEquals(UnicodeString('Hello'), JsStringToUnicodeString(JsGetProperty(Context.Global, 's1')), 's1');
    CheckEquals(UnicodeString('Hello'), JsStringToUnicodeString(JsGetProperty(Context.Global, 's2')), 's2');
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

procedure TNativeClassTestCase.TestClassProjectedTwice;
begin
  TestProjectedClass;
  TestProjectedClass;
end;

procedure TNativeClassTestCase.TestClassProjectedInMultipleContexts;
const
  SScript: UnicodeString = 'var obj = new TestObject(); var s1 = obj.method1(); obj.prop1 = s1; var s2 = obj.prop1;';
var
  Runtime: TChakraCoreRuntime;
  Context1, Context2: TChakraCoreContext;
begin
  Runtime := nil;
  Context1 := nil;
  Context2 := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context1 := TChakraCoreContext.Create(Runtime);
    Context2 := TChakraCoreContext.Create(Runtime);

    Context1.Activate;
    TTestObject1.Project('TestObject');
    Context1.RunScript(SScript, UnicodeString('TestProjectedClass1.js'));
    CheckEquals(UnicodeString('Hello'), JsStringToUnicodeString(JsGetProperty(Context1.Global, 's1')), 's1');
    CheckEquals(UnicodeString('Hello'), JsStringToUnicodeString(JsGetProperty(Context1.Global, 's2')), 's2');

    Context2.Activate;
    TTestObject1.Project('TestObject');
    Context2.RunScript(SScript, UnicodeString('TestProjectedClass2.js'));
    CheckEquals(UnicodeString('Hello'), JsStringToUnicodeString(JsGetProperty(Context2.Global, 's1')), 's1');
    CheckEquals(UnicodeString('Hello'), JsStringToUnicodeString(JsGetProperty(Context2.Global, 's2')), 's2');
  finally
    Context2.Free;
    Context1.Free;
    Runtime.Free;
  end;
end;

{ TRectangle }

type
  TRectangle = class(TNativeObject)
    class procedure InitializeInstance(AInstance: JsValueRef; Args: PJsValueRef; ArgCount: Word); override;
    class function InitializePrototype(AConstructor: JsValueRef): JsValueRef; override;
  end;

class procedure TRectangle.InitializeInstance(AInstance: JsValueRef; Args: PJsValueRef; ArgCount: Word);
var
  ArgsArray: PJsValueRefArray absolute Args;
  ShapeCtr: JsValueRef;
begin
  if Self = TRectangle then
  begin
    // Shape.call(x, y);
    ShapeCtr := JsGetProperty(JsGlobal, 'Shape');
    JsCallFunction(ShapeCtr, [ArgsArray^[0], ArgsArray^[1]], AInstance);

    // this.w = w;
    JsSetProperty(AInstance, UnicodeString('w'), ArgsArray^[2]);
    // this.h = h;
    JsSetProperty(AInstance, UnicodeString('h'), ArgsArray^[3]);
  end
  else
    inherited InitializeInstance(AInstance, Args, ArgCount);
end;

class function TRectangle.InitializePrototype(AConstructor: JsValueRef): JsValueRef;
var
  ShapeCtr, ShapePrototype: JsValueRef;
begin
  if Self = TRectangle then
  begin
    ShapeCtr := JsGetProperty(JsGlobal, 'Shape');
    ShapePrototype := JsGetProperty(ShapeCtr, 'prototype');
    // Rectangle.prototype = Object.create(Shape.prototype);
    Result := JsCreateObject(ShapePrototype);
  end
  else
    Result := inherited InitializePrototype(AConstructor);
end;

procedure TNativeClassTestCase.TestInheritance;
// same tests as in TChakraCorePrototypes.TestInheritance, against ChakraCoreClasses.TNativeObject implementation
// - Shape (x, y) => Object
//   - Circle (x, y, r) => Shape (x, y)
//   - Rectangle (x, y, w, h) => Shape (x, y)
//     - Square (x, y, w) => Rectangle (x, y, w, w)
const
  SScript =
    // Shape: (Javascript) superclass
    'function Shape(x, y) {'                                     + sLineBreak +
    '  this.x = x;'                                              + sLineBreak +
    '  this.y = y;'                                              + sLineBreak +
    '}'                                                          + sLineBreak +
                                                                   sLineBreak +
    'Shape.prototype.move = function(x, y) {'                    + sLineBreak +
    '  this.x += x;'                                             + sLineBreak +
    '  this.y += y;'                                             + sLineBreak +
    '};'                                                         + sLineBreak +
                                                                   sLineBreak +
    // Circle: (Javascript) subclass of (Javascript) Shape
    'function Circle(x, y, r) {'                                 + sLineBreak +
    '  Shape.call(this, x, y);'                                  + sLineBreak +
    '  this.r = r;'                                              + sLineBreak +
    '}'                                                          + sLineBreak +
                                                                   sLineBreak +
    'Circle.prototype = Object.create(Shape.prototype);'         + sLineBreak +
    'Circle.prototype.constructor = Circle;'                     + sLineBreak +
                                                                   sLineBreak +
    // Square: (Javascript) subclass of (native) Rectangle
    'function Square(x, y, w) {'                                 + sLineBreak +
    '  Rectangle.call(this, x, y, w, w);'                        + sLineBreak +
    '}'                                                          + sLineBreak +
                                                                   sLineBreak +
    'Square.prototype = Object.create(Rectangle.prototype);'     + sLineBreak +
    'Square.prototype.constructor = Square;';
  SName = 'TestInheritance.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
  ShapeObj, CircleObj, RectangleObj, SquareObj: JsValueRef;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TRectangle.Project('Rectangle');

    JsRunScript(SScript, SName);

    // var shapeObj = new Shape(10, 10);
    ShapeObj := JsNew('Shape', [IntToJsNumber(10), IntToJsNumber(10)]);
    CheckValueType(JsObject, ShapeObj, 'shapeObj value type');
    CheckTrue(JsInstanceOf(ShapeObj, 'Shape'), 'shapeObj instanceof Shape');
    CheckFalse(JsInstanceOf(ShapeObj, 'Circle'), 'shapeObj instanceof Circle');
    CheckFalse(JsInstanceOf(ShapeObj, 'Rectangle'), 'shapeObj instanceof Rectangle');
    CheckFalse(JsInstanceOf(ShapeObj, 'Square'), 'shapeObj instanceof Square');

    CheckEquals(10, JsNumberToInt(JsGetProperty(ShapeObj, 'x')), 'shapeObj.x before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(ShapeObj, 'y')), 'shapeObj.y before move');
    JsCallFunction('move', [IntToJsNumber(10), IntToJsNumber(10)], ShapeObj);
    CheckEquals(20, JsNumberToInt(JsGetProperty(ShapeObj, 'x')), 'shapeObj.x after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(ShapeObj, 'y')), 'shapeObj.y after move');

    // var circleObj = new Circle(10, 10, 10);
    CircleObj := JsNew('Circle', [IntToJsNumber(10), IntToJsNumber(10), IntToJsNumber(10)]);
    CheckValueType(JsObject, CircleObj, 'circleObj value type');
    CheckTrue(JsInstanceOf(CircleObj, 'Shape'), 'circleObj instanceof Shape');
    CheckTrue(JsInstanceOf(CircleObj, 'Circle'), 'circleObj instanceof Circle');
    CheckFalse(JsInstanceOf(CircleObj, 'Rectangle'), 'circleObj instanceof Rectangle');
    CheckFalse(JsInstanceOf(CircleObj, 'Square'), 'circleObj instanceof Square');

    CheckEquals(10, JsNumberToInt(JsGetProperty(CircleObj, 'x')), 'circleObj.x before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(CircleObj, 'y')), 'circleObj.y before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(CircleObj, 'r')), 'circleObj.r before move');
    JsCallFunction('move', [IntToJsNumber(10), IntToJsNumber(10)], CircleObj);
    CheckEquals(20, JsNumberToInt(JsGetProperty(CircleObj, 'x')), 'circleObj.x after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(CircleObj, 'y')), 'circleObj.y after move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(CircleObj, 'r')), 'circleObj.r after move');

    // var rectangleObj = new Rectangle(10, 10, 60, 40);
    RectangleObj := JsNew('Rectangle', [IntToJsNumber(10), IntToJsNumber(10), IntToJsNumber(60), IntToJsNumber(40)]);
    CheckValueType(JsObject, RectangleObj, 'rectangleObj value type');
    CheckTrue(JsInstanceOf(RectangleObj, 'Shape'), 'rectangleObj instanceof Shape');
    CheckFalse(JsInstanceOf(RectangleObj, 'Circle'), 'rectangleObj instanceof Circle');
    CheckTrue(JsInstanceOf(RectangleObj, 'Rectangle'), 'rectangleObj instanceof Rectangle');
    CheckFalse(JsInstanceOf(RectangleObj, 'Square'), 'rectangleObj instanceof Square');

    CheckEquals(10, JsNumberToInt(JsGetProperty(RectangleObj, 'x')), 'rectangleObj.x before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(RectangleObj, 'y')), 'rectangleObj.y before move');
    CheckEquals(60, JsNumberToInt(JsGetProperty(RectangleObj, 'w')), 'rectangleObj.w before move');
    CheckEquals(40, JsNumberToInt(JsGetProperty(RectangleObj, 'h')), 'rectangleObj.h before move');
    JsCallFunction('move', [IntToJsNumber(10), IntToJsNumber(10)], RectangleObj);
    CheckEquals(20, JsNumberToInt(JsGetProperty(RectangleObj, 'x')), 'rectangleObj.x after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(RectangleObj, 'y')), 'rectangleObj.y after move');
    CheckEquals(60, JsNumberToInt(JsGetProperty(RectangleObj, 'w')), 'rectangleObj.w after move');
    CheckEquals(40, JsNumberToInt(JsGetProperty(RectangleObj, 'h')), 'rectangleObj.h after move');

    // var squareObj = new Square(10, 10, 20);
    SquareObj := JsNew('Square', [IntToJsNumber(10), IntToJsNumber(10), IntToJsNumber(20)]);
    CheckValueType(JsObject, SquareObj, 'squareObj value type');
    CheckTrue(JsInstanceOf(SquareObj, 'Shape'), 'squareObj instanceof Shape');
    CheckFalse(JsInstanceOf(SquareObj, 'Circle'), 'squareObj instanceof Circle');
    CheckTrue(JsInstanceOf(SquareObj, 'Rectangle'), 'squareObj instanceof Rectangle');
    CheckTrue(JsInstanceOf(SquareObj, 'Square'), 'squareObj instanceof Square');

    CheckEquals(10, JsNumberToInt(JsGetProperty(SquareObj, 'x')), 'squareObj.x before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(SquareObj, 'y')), 'sqaureObj.y before move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'w')), 'squareObj.w before move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'h')), 'squareObj.h before move');
    JsCallFunction('move', [IntToJsNumber(10), IntToJsNumber(10)], SquareObj);
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'x')), 'squareObj.x after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'y')), 'squareObj.y after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'w')), 'squareObj.w after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'h')), 'squareObj.h after move');
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

type

  { TSquare }

  TSquare = class(TRectangle)
    class procedure InitializeInstance(AInstance: JsValueRef; Args: PJsValueRef; ArgCount: Word); override;
  end;

{ TSquare }

class procedure TSquare.InitializeInstance(AInstance: JsValueRef; Args: PJsValueRef; ArgCount: Word);
var
  ArgsArray: PJsValueRefArray absolute Args;
  RectangleArgs: array[0..3] of JsValueRef;
begin
  // Rectangle.call(this, x, y, w, w);
  RectangleArgs[0] := ArgsArray^[0];
  RectangleArgs[1] := ArgsArray^[1];
  RectangleArgs[2] := ArgsArray^[2];
  RectangleArgs[3] := ArgsArray^[2];
  inherited InitializeInstance(AInstance, @RectangleArgs[0], 4);
end;

procedure TNativeClassTestCase.TestInheritance2;
const
  SScript =
    // Shape: (Javascript) superclass
    'function Shape(x, y) {'                                     + sLineBreak +
    '  this.x = x;'                                              + sLineBreak +
    '  this.y = y;'                                              + sLineBreak +
    '}'                                                          + sLineBreak +
                                                                   sLineBreak +
    'Shape.prototype.move = function(x, y) {'                    + sLineBreak +
    '  this.x += x;'                                             + sLineBreak +
    '  this.y += y;'                                             + sLineBreak +
    '};'                                                         + sLineBreak +
                                                                   sLineBreak +
    // Circle: (Javascript) subclass of (Javascript) Shape
    'function Circle(x, y, r) {'                                 + sLineBreak +
    '  Shape.call(this, x, y);'                                  + sLineBreak +
    '  this.r = r;'                                              + sLineBreak +
    '}'                                                          + sLineBreak +
                                                                   sLineBreak +
    'Circle.prototype = Object.create(Shape.prototype);'         + sLineBreak +
    'Circle.prototype.constructor = Circle;';
  SName = 'TestInheritance2.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
  ShapeObj, CircleObj, RectangleObj, SquareObj: JsValueRef;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TRectangle.Project('Rectangle');
    TSquare.Project('Square');

    JsRunScript(SScript, SName);

    // var shapeObj = new Shape(10, 10);
    ShapeObj := JsNew('Shape', [IntToJsNumber(10), IntToJsNumber(10)]);
    CheckValueType(JsObject, ShapeObj, 'shapeObj value type');
    CheckTrue(JsInstanceOf(ShapeObj, 'Shape'), 'shapeObj instanceof Shape');
    CheckFalse(JsInstanceOf(ShapeObj, 'Circle'), 'shapeObj instanceof Circle');
    CheckFalse(JsInstanceOf(ShapeObj, 'Rectangle'), 'shapeObj instanceof Rectangle');
    CheckFalse(JsInstanceOf(ShapeObj, 'Square'), 'shapeObj instanceof Square');

    CheckEquals(10, JsNumberToInt(JsGetProperty(ShapeObj, 'x')), 'shapeObj.x before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(ShapeObj, 'y')), 'shapeObj.y before move');
    JsCallFunction('move', [IntToJsNumber(10), IntToJsNumber(10)], ShapeObj);
    CheckEquals(20, JsNumberToInt(JsGetProperty(ShapeObj, 'x')), 'shapeObj.x after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(ShapeObj, 'y')), 'shapeObj.y after move');

    // var circleObj = new Circle(10, 10, 10);
    CircleObj := JsNew('Circle', [IntToJsNumber(10), IntToJsNumber(10), IntToJsNumber(10)]);
    CheckValueType(JsObject, CircleObj, 'circleObj value type');
    CheckTrue(JsInstanceOf(CircleObj, 'Shape'), 'circleObj instanceof Shape');
    CheckTrue(JsInstanceOf(CircleObj, 'Circle'), 'circleObj instanceof Circle');
    CheckFalse(JsInstanceOf(CircleObj, 'Rectangle'), 'circleObj instanceof Rectangle');
    CheckFalse(JsInstanceOf(CircleObj, 'Square'), 'circleObj instanceof Square');

    CheckEquals(10, JsNumberToInt(JsGetProperty(CircleObj, 'x')), 'circleObj.x before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(CircleObj, 'y')), 'circleObj.y before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(CircleObj, 'r')), 'circleObj.r before move');
    JsCallFunction('move', [IntToJsNumber(10), IntToJsNumber(10)], CircleObj);
    CheckEquals(20, JsNumberToInt(JsGetProperty(CircleObj, 'x')), 'circleObj.x after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(CircleObj, 'y')), 'circleObj.y after move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(CircleObj, 'r')), 'circleObj.r after move');

    // var rectangleObj = new Rectangle(10, 10, 60, 40);
    RectangleObj := JsNew('Rectangle', [IntToJsNumber(10), IntToJsNumber(10), IntToJsNumber(60), IntToJsNumber(40)]);
    CheckValueType(JsObject, RectangleObj, 'rectangleObj value type');
    CheckTrue(JsInstanceOf(RectangleObj, 'Shape'), 'rectangleObj instanceof Shape');
    CheckFalse(JsInstanceOf(RectangleObj, 'Circle'), 'rectangleObj instanceof Circle');
    CheckTrue(JsInstanceOf(RectangleObj, 'Rectangle'), 'rectangleObj instanceof Rectangle');
    CheckFalse(JsInstanceOf(RectangleObj, 'Square'), 'rectangleObj instanceof Square');

    CheckEquals(10, JsNumberToInt(JsGetProperty(RectangleObj, 'x')), 'rectangleObj.x before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(RectangleObj, 'y')), 'rectangleObj.y before move');
    CheckEquals(60, JsNumberToInt(JsGetProperty(RectangleObj, 'w')), 'rectangleObj.w before move');
    CheckEquals(40, JsNumberToInt(JsGetProperty(RectangleObj, 'h')), 'rectangleObj.h before move');
    JsCallFunction('move', [IntToJsNumber(10), IntToJsNumber(10)], RectangleObj);
    CheckEquals(20, JsNumberToInt(JsGetProperty(RectangleObj, 'x')), 'rectangleObj.x after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(RectangleObj, 'y')), 'rectangleObj.y after move');
    CheckEquals(60, JsNumberToInt(JsGetProperty(RectangleObj, 'w')), 'rectangleObj.w after move');
    CheckEquals(40, JsNumberToInt(JsGetProperty(RectangleObj, 'h')), 'rectangleObj.h after move');

    // var squareObj = new Square(10, 10, 20);
    SquareObj := JsNew('Square', [IntToJsNumber(10), IntToJsNumber(10), IntToJsNumber(20)]);
    CheckValueType(JsObject, SquareObj, 'squareObj value type');
    CheckTrue(JsInstanceOf(SquareObj, 'Shape'), 'squareObj instanceof Shape');
    CheckFalse(JsInstanceOf(SquareObj, 'Circle'), 'squareObj instanceof Circle');
    CheckTrue(JsInstanceOf(SquareObj, 'Rectangle'), 'squareObj instanceof Rectangle');
    CheckTrue(JsInstanceOf(SquareObj, 'Square'), 'squareObj instanceof Square');

    CheckEquals(10, JsNumberToInt(JsGetProperty(SquareObj, 'x')), 'squareObj.x before move');
    CheckEquals(10, JsNumberToInt(JsGetProperty(SquareObj, 'y')), 'sqaureObj.y before move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'w')), 'squareObj.w before move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'h')), 'squareObj.h before move');
    JsCallFunction('move', [IntToJsNumber(10), IntToJsNumber(10)], SquareObj);
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'x')), 'squareObj.x after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'y')), 'squareObj.y after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'w')), 'squareObj.w after move');
    CheckEquals(20, JsNumberToInt(JsGetProperty(SquareObj, 'h')), 'squareObj.h after move');
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

var
  CreatedCount: Integer = 0;
  DestroyedCount: Integer = 0;

type
  TTestObject2 = class(TNativeObject)
  public
    constructor Create(Args: PJsValueRef = nil; ArgCount: Word = 0; AFinalize: Boolean = False); override;
    destructor Destroy; override;
  end;

constructor TTestObject2.Create(Args: PJsValueRef; ArgCount: Word; AFinalize: Boolean);
begin
  inherited Create(Args, ArgCount, AFinalize);
  Inc(CreatedCount);
end;

destructor TTestObject2.Destroy;
begin
  Inc(DestroyedCount);
  inherited Destroy;
end;

function Get_Alive(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRef; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := BooleanToJsBoolean(DestroyedCount = 0);
end;

// see that the finalizer gets called for a native instance if/when GC runs
procedure TNativeClassTestCase.TestFinalizer;
const
  SScript =
    // create native instance from script
    'var obj = new TestObject2();'                               + sLineBreak +
    // release reference
    'obj = null;'                                                + sLineBreak +
    // wait for GC
    'while (alive) {'                                            + sLineBreak +
      // do some allocation to trigger GC eventually
    '  var obj = new Object();'                                  + sLineBreak +
    '}';
  SName = 'TestFinalizer.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TTestObject2.Project;
    JsDefineProperty('alive', False, False, JsCreateFunction(@Get_Alive, nil, UnicodeString('')), nil);

    CreatedCount := 0;
    DestroyedCount := 0;
    JsRunScript(SScript, SName);

    CheckEquals(1, CreatedCount, 'constructor calls');
    CheckEquals(1, DestroyedCount, 'destructor calls');
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

// see that the finalizer gets called for a native instance if/when GC runs, or when the runtime is disposed
procedure TNativeClassTestCase.TestFinalizer2;
const
  SScript =
    'var obj = new TestObject2();'                               + sLineBreak +
    'obj = null;';
  SName = 'TestFinalizer2.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TTestObject2.Project;

    CreatedCount := 0;
    DestroyedCount := 0;
    JsRunScript(SScript, SName);
  finally
    Context.Free;
    Runtime.Free;

    CheckEquals(1, CreatedCount, 'constructor calls');
    CheckEquals(1, DestroyedCount, 'destructor calls');
  end;
end;

// see that the finalizer gets called for a native instance if/when GC runs (invoked by host)
procedure TNativeClassTestCase.TestFinalizer3;
const
  SScript =
    'var obj = new TestObject2();'                               + sLineBreak +
    'obj = null;';
  SName = 'TestFinalizer3.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create([ccroDisableBackgroundWork]); // doesn't seem to work with background GC
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TTestObject2.Project;

    CreatedCount := 0;
    DestroyedCount := 0;
    JsRunScript(SScript, SName);
    Runtime.CollectGarbage;

    CheckEquals(1, CreatedCount, 'constructor calls');
    CheckEquals(1, DestroyedCount, 'destructor calls');
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

const
  FinalizerLoopCount = 10000;

// see that repeated construction of a projected class no longer causes access violation
// (constructors addrefed to prevent premature GC)
procedure TNativeClassTestCase.TestFinalizer4;
const
  SScript =
    'var obj = new TestObject2();'                               + sLineBreak +
    'obj = null;'                                                + sLineBreak +
    '';
  SName = 'TestFinalizer4.js';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
  I: Integer;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TTestObject2.Project;

    CreatedCount := 0;
    DestroyedCount := 0;
    for I := 0 to FinalizerLoopCount - 1 do
      Context.RunScript(SScript, SName);
  finally
    Context.Free;
    Runtime.Free;

    CheckNotEquals(0, CreatedCount, 'constructor calls');
    CheckEquals(CreatedCount, DestroyedCount, 'destructor calls');
  end;
end;

initialization

{$ifdef FPC}
  RegisterTests([TChakraCoreContextTestCase, TNativeClassTestCase]);
{$else}
  RegisterTests([TChakraCoreContextTestCase.Suite, TNativeClassTestCase.Suite]);
{$endif}

end.
