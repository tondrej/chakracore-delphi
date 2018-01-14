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
{$ifdef WINDOWS}
  Windows,
{$endif}
  SysUtils, Classes,
{$ifdef HAS_WIDESTRUTILS}
  WideStrUtils,
{$endif}
  Compat, ChakraCommon, ChakraCoreUtils, ChakraCoreClasses;

type
  TInfoLevel = (ilNone, ilInfo, ilWarn, ilError);

  TConsole = class(TChakraCoreNativeObject)
  private
    function Assert(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
    function Log(Arguments: PJsValueRef; ArgumentCount: Word; Level: TInfoLevel): JsValueRef;
    function LogError(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
    function LogInfo(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
    function LogNone(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
    function LogWarn(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
    procedure Print(const S: UTF8String; Level: TInfoLevel = ilNone; UseAnsiColors: Boolean = True); overload;
    procedure Print(const S: UnicodeString; Level: TInfoLevel = ilNone; UseAnsiColors: Boolean = True); overload;
  protected
    class procedure RegisterMethods(AInstance: JsValueRef); override;
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

function TConsole.Assert(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
var
  ArgCondition: JsValueRef;
  SMessage: UnicodeString;
begin
  Result := JsUndefinedValue;
  if ArgumentCount < 1 then
    Exit;

  SMessage := 'Assertion failed';

  // arg 1 = condition (boolean)
  ArgCondition := Arguments^;
  if (JsGetValueType(ArgCondition) <> JsBoolean) then
    raise Exception.Create('condition passed to console.assert not a boolean');

  Inc(Arguments);
  Dec(ArgumentCount);

  if (JsBooleanToBoolean(ArgCondition)) then // assertion passed
    Exit;

  if ArgumentCount = 0 then // no message/data
    Print(SMessage, ilError)
  else
    Log(Arguments, ArgumentCount, ilError);
end;

function TConsole.Log(Arguments: PJsValueRef; ArgumentCount: Word; Level: TInfoLevel): JsValueRef;
var
  FirstArg, S, SCopy: UnicodeString;
  P, PPrev: PWideChar;
  Arg: PJsValueRef;
  I, ArgIndex: Integer;
begin
  Result := JsUndefinedValue;
  if not Assigned(Arguments) then
    Exit;

  S := '';
  P := nil;
  PPrev := nil;
  Arg := Arguments;
  ArgIndex := 0;
  if Assigned(Arguments) and (ArgumentCount > 0) and (JsGetValueType(Arguments^) = JsString) then
  begin
    FirstArg := JsStringToUnicodeString(Arguments^);
    PPrev := PWideChar(FirstArg);
    P := FmtSpecPos(PPrev);
  end;

  if Assigned(P) then
  begin
    Inc(Arg);
    Inc(ArgIndex);
    while Assigned(P) do
    begin
      if ArgIndex > ArgumentCount - 1 then
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
            S := S + JsInspect('', Arg^);
          's':
            S := S + JsStringToUnicodeString(Arg^);
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
    for I := 0 to ArgumentCount - 1 do
    begin
      S := S + JsStringToUnicodeString(Arg^);
      Inc(Arg);
    end;
  end;
  Print(S, Level, {$ifdef WINDOWS}False{$else}True{$endif}); // TODO Windows 10 console supports ANSI colors
end;

function TConsole.LogError(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
begin
  Result := Log(Arguments, ArgumentCount, ilError);
end;

function TConsole.LogInfo(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
begin
  Result := Log(Arguments, ArgumentCount, ilInfo);
end;

function TConsole.LogNone(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
begin
  Result := Log(Arguments, ArgumentCount, ilNone);
end;

function TConsole.LogWarn(Arguments: PJsValueRef; ArgumentCount: Word): JsValueRef;
begin
  Result := Log(Arguments, ArgumentCount, ilWarn);
end;

procedure TConsole.Print(const S: UTF8String; Level: TInfoLevel; UseAnsiColors: Boolean);
const
  StartBlocks: array[TInfoLevel] of RawByteString = ('', #$1b'[32;1m', #$1b'[33;1m', #$1b'[31;1m');
  EndBlocks: array[Boolean] of RawByteString = ('', #$1b'[0m');
{$ifdef WINDOwS}
  BackgroundMask = $F0;
  TextColors: array[TInfoLevel] of Word = (0, FOREGROUND_GREEN or FOREGROUND_INTENSITY,
    FOREGROUND_GREEN or FOREGROUND_RED or FOREGROUND_INTENSITY, FOREGROUND_RED or FOREGROUND_INTENSITY);
var
  Info: TConsoleScreenBufferInfo;
{$endif}
begin
{$ifdef WINDOWS}
  if UseAnsiColors then
    Writeln(StartBlocks[Level], S, EndBlocks[Level <> ilNone])
  else
  begin
    if (Level = ilNone) or not GetConsoleScreenBufferInfo(TTextRec(Output).Handle, Info) then
    begin
      Writeln(S);
      Exit;
    end;

    SetConsoleTextAttribute(TTextRec(Output).Handle, Info.wAttributes and BackgroundMask or TextColors[Level]);
    try
      Writeln(S);
    finally
      SetConsoleTextAttribute(TTextRec(Output).Handle, Info.wAttributes);
    end;
  end;
{$else}
  Writeln(StartBlocks[Level], S, EndBlocks[Level <> ilNone]);
{$endif}
end;

procedure TConsole.Print(const S: UnicodeString; Level: TInfoLevel; UseAnsiColors: Boolean);
begin
  Print(UTF8Encode(S), Level, UseAnsiColors);
end;

{ TConsole protected }

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
