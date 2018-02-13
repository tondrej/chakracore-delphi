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

unit Test_Classes;

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
  Compat, ChakraCoreVersion, ChakraCommon, ChakraCore, ChakraCoreUtils, ChakraCoreClasses,
  Test_ChakraCore;

type
  TChakraCoreContextTestCase = class(TBaseTestCase)
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
  end;

implementation

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
  public
  end;

{ TTestObject1 }

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
    Runtime := TChakraCoreRuntime.Create([]);
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TestObject := TTestObject1.Create;
    JsSetProperty(Context.Global, 'obj', TestObject.Instance);
    Result := Context.RunScript('obj.method1(null, null);', 'TestMethod1.js');
    Check(TestObject.FMethod1Called, 'method1 called');
    CheckValueType(JsString, Result, 'method1 result type');
    CheckEquals('Hello', JsStringToUnicodeString(Result), 'method1 result');
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
    Runtime := TChakraCoreRuntime.Create([]);
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TestObject := TTestObject1.Create;
    JsSetProperty(Context.Global, 'obj', TestObject.Instance);
    Result := Context.CallFunction('method1', [], TestObject.Instance);
    Check(TestObject.FMethod1Called, 'method1 called');
    CheckValueType(JsString, Result, 'method1 result type');
    CheckEquals('Hello', JsStringToUnicodeString(Result), 'method1 result');
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
    Runtime := TChakraCoreRuntime.Create([]);
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TestObject := TTestObject1.Create;
    JsSetProperty(Context.Global, 'obj', TestObject.Instance);
    Context.RunScript(WideFormat('obj.prop1 = ''%s'';', [SValue]), 'TestNamedProperty.js');
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
  SScript = 'var obj = new TestObject(); var s1 = obj.method1(); obj.prop1 = s1; var s2 = obj.prop1;';
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
begin
  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create([]);
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;
    TTestObject1.Project('TestObject');
    Context.RunScript(SScript, 'TestProjectedClass.js');
    CheckEquals('Hello', JsStringToUnicodeString(JsGetProperty(Context.Global, 's1')), 's1');
    CheckEquals('Hello', JsStringToUnicodeString(JsGetProperty(Context.Global, 's2')), 's2');
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
  SScript = 'var obj = new TestObject(); var s1 = obj.method1(); obj.prop1 = s1; var s2 = obj.prop1;';
var
  Runtime: TChakraCoreRuntime;
  Context1, Context2: TChakraCoreContext;
begin
  Runtime := nil;
  Context1 := nil;
  Context2 := nil;
  try
    Runtime := TChakraCoreRuntime.Create([]);
    Context1 := TChakraCoreContext.Create(Runtime);
    Context2 := TChakraCoreContext.Create(Runtime);

    Context1.Activate;
    TTestObject1.Project('TestObject');
    Context1.RunScript(SScript, 'TestProjectedClass1.js');
    CheckEquals('Hello', JsStringToUnicodeString(JsGetProperty(Context1.Global, 's1')), 's1');
    CheckEquals('Hello', JsStringToUnicodeString(JsGetProperty(Context1.Global, 's2')), 's2');

    Context2.Activate;
    TTestObject1.Project('TestObject');
    Context2.RunScript(SScript, 'TestProjectedClass2.js');
    CheckEquals('Hello', JsStringToUnicodeString(JsGetProperty(Context2.Global, 's1')), 's1');
    CheckEquals('Hello', JsStringToUnicodeString(JsGetProperty(Context2.Global, 's2')), 's2');
  finally
    Context2.Free;
    Context1.Free;
    Runtime.Free;
  end;
end;

initialization

{$ifdef FPC}
  RegisterTests([{TChakraCoreContextTestCase,} TNativeClassTestCase]);
{$else}
  RegisterTests([{TChakraCoreContextTestCase.Suite,} TNativeClassTestCase.Suite]);
{$endif}

end.
