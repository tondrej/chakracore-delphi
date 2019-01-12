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

program SimpleHost;

{$APPTYPE CONSOLE}

{$include common.inc}

uses
  {$ifdef FPC}{$ifdef UNIX}
  cthreads,
  {$endif}{$endif}
  SysUtils, Classes,
  Compat,
  ChakraCoreVersion, ChakraCommon, ChakraCoreUtils, ChakraCoreClasses;

{$R *.res}

function Console_Log(Callee: JsValueRef; IsConstructCall: bool; Args: PJsValueRefArray; ArgCount: Word;
  CallbackState: Pointer): JsValueRef; {$ifdef WINDOWS}stdcall;{$else}cdecl;{$endif}
begin
  Result := JsUndefinedValue;
  try
    if not Assigned(Args) or (ArgCount < 2) then
      Exit;

    Writeln(JsStringToUTF8String(Args^[1]));
  except on E: Exception do
    JsThrowError(WideFormat('[%s] %s', [E.ClassName, E.Message]));
  end;
end;

function LoadFile(const FileName: UnicodeString): UnicodeString;
var
  FileStream: TFileStream;
  S: UTF8String;
begin
  Result := '';

{$ifdef UNICODE}
  FileStream := TFileStream.Create(FileName, fmOpenRead);
{$else}
  FileStream := TFileStream.Create(UTF8Encode(FileName), fmOpenRead);
{$endif}
  try
    if FileStream.Size = 0 then
      Exit;

    SetLength(S, FileStream.Size);
    FileStream.Read(S[1], FileStream.Size);

    Result := UTF8ToString(S);
  finally
    FileStream.Free;
  end;
end;

procedure Main;
var
  Runtime: TChakraCoreRuntime;
  Context: TChakraCoreContext;
  Console: JsValueRef;
begin
  if ParamCount = 0 then
    Exit;

  Runtime := nil;
  Context := nil;
  try
    Runtime := TChakraCoreRuntime.Create;
    Context := TChakraCoreContext.Create(Runtime);
    Context.Activate;

    Console := JsCreateObject;
    JsSetCallback(Console, 'log', @Console_Log, nil);
    JsSetProperty(Context.Global, 'console', Console);

{$ifdef UNICODE}
    Context.RunScript(LoadFile(ParamStr(1)), ExtractFileName(Paramstr(1)));
{$else}
    Context.RunScript(LoadFile(UTF8Decode(ParamStr(1))), ExtractFileName(UTF8Decode(Paramstr(1))));
{$endif}
  finally
    Context.Free;
    Runtime.Free;
  end;
end;

begin
{$ifdef DELPHI2006_UP}
  ReportMemoryLeaksOnShutdown := True;
{$endif}
  try
    Main;
  except
    on E: EChakraCoreScript do
    begin
      ExitCode := 1;
      Writeln(Format('%s (%d, %d): [%s] %s', [E.ScriptURL, E.Line + 1, E.Column + 1, E.ClassName, E.Message]));
    end;
    on E: Exception do
    begin
      ExitCode := 1;
      Writeln(Format('[%s] %s', [E.ClassName, E.Message]));
    end;
  end;
end.
