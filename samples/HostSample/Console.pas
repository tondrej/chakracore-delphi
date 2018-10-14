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

unit Console;

interface

{$include common.inc}

uses
  SysUtils, Classes,
{$ifdef HAS_WIDESTRUTILS}
  WideStrUtils,
{$endif}
  Compat, ChakraCommon, ChakraCoreUtils, ChakraCoreClasses;

type
  TInfoLevel = (ilNone, ilInfo, ilWarn, ilError);

  TConsolePrintEvent = procedure (Sender: TObject; const Text: UnicodeString; Level: TInfoLevel = ilNone) of object;

  TConsole = class(TNativeObject)
  private
    FOnPrint: TConsolePrintEvent;
    
    function Assert(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function LogError(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function LogInfo(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function LogNone(Args: PJsValueRef; ArgCount: Word): JsValueRef;
    function LogWarn(Args: PJsValueRef; ArgCount: Word): JsValueRef;
  protected
    procedure DoPrint(const Text: UnicodeString; Level: TInfoLevel = ilNone); virtual;
    function Log(Args: PJsValueRef; ArgCount: Word; Level: TInfoLevel): JsValueRef;
    class procedure RegisterMethods(AInstance: JsValueRef); override;
  public
    property OnPrint: TConsolePrintEvent read FOnPrint write FOnPrint;
  end;

implementation

function FmtSpecPos(S: PWideChar): PWideChar;
var
  P: PWideChar;
begin
  Result := nil;

  P := WStrPos(S, '%');
  while Assigned(P) do
  begin
    case (P + 1)^ of
      #0:
        Break;
      'd', 'i', 'f', 'o', 's':
        begin
          Result := P;
          Break;
        end;
      '%':
        begin
          Inc(P);
          if P^ = #0 then
            Break;
        end;
    end;

    P := WStrPos(P + 1, '%');
  end;
end;

{ TConsole private }

function TConsole.Assert(Args: PJsValueRef; ArgCount: Word): JsValueRef;
var
  ArgCondition: JsValueRef;
  SMessage: UnicodeString;
begin
  Result := JsUndefinedValue;
  if ArgCount < 1 then
    Exit;

  SMessage := 'Assertion failed';

  // arg 1 = condition (boolean)
  ArgCondition := Args^;
  if (JsGetValueType(ArgCondition) <> JsBoolean) then
    raise Exception.Create('condition passed to console.assert not a boolean');

  Inc(Args);
  Dec(ArgCount);

  if (JsBooleanToBoolean(ArgCondition)) then // assertion passed
    Exit;

  if ArgCount = 0 then // no message/data
    DoPrint(SMessage, ilError)
  else
    Log(Args, ArgCount, ilError);
end;

function TConsole.LogError(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := Log(Args, ArgCount, ilError);
end;

function TConsole.LogInfo(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := Log(Args, ArgCount, ilInfo);
end;

function TConsole.LogNone(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := Log(Args, ArgCount, ilNone);
end;

function TConsole.LogWarn(Args: PJsValueRef; ArgCount: Word): JsValueRef;
begin
  Result := Log(Args, ArgCount, ilWarn);
end;

{ TConsole protected }

procedure TConsole.DoPrint(const Text: UnicodeString; Level: TInfoLevel);
begin
  if Assigned(FOnPrint) then
    FOnPrint(Self, Text, Level);
end;

function TConsole.Log(Args: PJsValueRef; ArgCount: Word; Level: TInfoLevel): JsValueRef;
var
  FirstArg, S, SCopy: UnicodeString;
  P, PPrev: PWideChar;
  Arg: PJsValueRef;
  I, ArgIndex: Integer;
begin
  Result := JsUndefinedValue;
  if not Assigned(Args) then
    Exit;

  S := '';
  P := nil;
  PPrev := nil;
  Arg := Args;
  ArgIndex := 0;
  if Assigned(Args) and (ArgCount > 0) and (JsGetValueType(Args^) = JsString) then
  begin
    FirstArg := JsStringToUnicodeString(Args^);
    PPrev := PWideChar(FirstArg);
    P := FmtSpecPos(PPrev);
  end;

  if Assigned(P) then
  begin
    Inc(Arg);
    Inc(ArgIndex);
    while Assigned(P) do
    begin
      if ArgIndex > ArgCount - 1 then
      begin
        SetString(SCopy, PPrev, (P - PPrev) + 2);
        S := S + WideStringReplace(SCopy, '%%', '%', [rfReplaceAll]);
      end
      else
      begin
        SetString(SCopy, PPrev, P - PPrev);
        S := S + WideStringReplace(SCopy, '%%', '%', [rfReplaceAll]);
        case (P + 1)^ of
          'd', 'i':
            S := S + UnicodeString(IntToStr(JsNumberToInt(Arg^)));
          'f':
            S := S + UnicodeString(FloatToStr(JsNumberToDouble(Arg^), DefaultFormatSettings));
          'o':
            S := S + JsInspect(Arg^);
          's':
            S := S + JsStringToUnicodeString(JsValueAsJsString(Arg^));
        end;
      end;

      PPrev := P + 2;
      P := FmtSpecPos(PPrev);
      Inc(Arg);
      Inc(ArgIndex);
    end;
    S := S + WideStringReplace(PPrev, '%%', '%', [rfReplaceAll]);
  end
  else
  begin
    for I := 0 to ArgCount - 1 do
    begin
      if S <> '' then
        S := S + ' ';
      S := S + JsStringToUnicodeString(JsValueAsJsString(Arg^));
      Inc(Arg);
    end;
  end;
  DoPrint(S, Level);
end;

class procedure TConsole.RegisterMethods(AInstance: JsValueRef);
begin
  RegisterMethod(AInstance, 'assert', @TConsole.Assert);
  RegisterMethod(AInstance, 'log', @TConsole.LogNone);
  RegisterMethod(AInstance, 'info', @TConsole.LogInfo);
  RegisterMethod(AInstance, 'warn', @TConsole.LogWarn);
  RegisterMethod(AInstance, 'error', @TConsole.LogError);
  RegisterMethod(AInstance, 'exception', @TConsole.LogError);
end;

end.
