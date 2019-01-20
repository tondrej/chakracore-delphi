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

unit NodeProcess;

interface

uses
  Classes, SysUtils,
  Compat, ChakraCommon, ChakraCoreUtils, ChakraCoreClasses,
  EventEmitter;

type

  { TProcess }

  TProcess = class(TEventEmitter)
  protected
    class procedure RegisterMethods(AInstance: JsValueRef); override;
    class procedure RegisterProperties(AInstance: JsValueRef); override;

    function _Binding(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function _Cwd(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  public
    function Binding(const ModuleName: UnicodeString): JsValueRef;
  end;

implementation

function _ArgV: JsValueRef;
var
  I: Integer;
begin
  Result := JsCreateArray(ParamCount);
  for I := 0 to ParamCount do
    JsSetIndexedProperty(Result, IntToJsNumber(I), StringToJsString(UnicodeString(ParamStr(I))));
end;

function _Env: JsValueRef;
{$ifdef FPC}
var
  I: Integer;
  S: array of AnsiString;
{$endif FPC}
begin
  Result := JsCreateObject;
// TODO: implement for Delphi
{$ifdef FPC}
  for I := 0 to GetEnvironmentVariableCount - 1 do
  begin
    S := GetEnvironmentString(I).Split(['=']);
    if (Length(S) > 1) and (not S[0].IsEmpty) then
      JsSetProperty(Result, S[0], StringToJsString(S[1]));
  end;
{$endif FPC}
end;

{ TProcess protected }

class procedure TProcess.RegisterMethods(AInstance: JsValueRef);
begin
  RegisterMethod(AInstance, 'binding', @TProcess._Binding);
  RegisterMethod(AInstance, 'cwd', @TProcess._Cwd);
end;

class procedure TProcess.RegisterProperties(AInstance: JsValueRef);
const
{$ifdef CPU64}
  sArch = 'x64';
{$else}
  sArch = 'x32';
{$endif}
{$ifdef MSWINDOWS}
  sPlatform = 'win32';
{$endif}
{$ifdef DARWIN}
  sPlatform = 'darwin';
{$endif}
{$ifdef LINUX}
  sPlatform = 'linux';
{$endif}
begin
  RegisterNamedProperty(AInstance, 'arch', False, True, False, StringToJsString(sArch));
  RegisterNamedProperty(AInstance, 'argv', False, True, False, _ArgV);
  RegisterNamedProperty(AInstance, 'execPath', False, True, False, StringToJsString(ParamStr(0)));
  RegisterNamedProperty(AInstance, 'env', False, True, False, _Env);
  RegisterNamedProperty(AInstance, 'pid', False, True, False, IntToJsNumber(0{GetProcessID}));
  RegisterNamedProperty(AInstance, 'platform', False, True, False, StringToJsString(sPlatform));
end;

function TProcess._Binding(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  try
    if not Assigned(Args) or (ArgCount <> 1) then
      raise Exception.Create('Invalid arguments');

    if (JsGetValueType(Args^) <> JsString) then
      raise Exception.Create('Invalid arguments');

    Result := Binding(JsStringToUnicodeString(Args^));
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TProcess._Cwd(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := JsUndefinedValue;
  try
    Result := StringToJsString(GetCurrentDir);
  except
    on E: Exception do
      JsThrowError(UnicodeFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function TProcess.Binding(const ModuleName: UnicodeString): JsValueRef;
begin
  Result := JsUndefinedValue;
  // TODO: node.js native bindings: buffer, uv, ...
end;

end.
