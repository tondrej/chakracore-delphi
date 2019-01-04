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

program WasmSample;

{$include common.inc}

uses
{$ifdef FPC}
  {$apptype GUI}
{$ifdef UNIX}
  cthreads,
{$endif UNIX}
  Interfaces,
{$endif FPC}
  Classes, SysUtils, Forms,
  Compat,
  ChakraCoreVersion,
  ChakraCoreUtils,
  WasmMainData in 'WasmMainData.pas' {DataModuleMain: TDataModule},
  WasmMainForm in 'WasmMainForm.pas' {FormMain};

{$R *.res}

type
  UnicodeStringDynArray = array of UnicodeString;

function ParamStrings: UnicodeStringDynArray;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, ParamCount);
  for I := 1 to ParamCount do
    Result[I - 1] := UnicodeString(ParamStr(I));
end;

begin
{$ifdef DELPHI2006_UP}
  ReportMemoryLeaksOnShutdown := True;
{$endif DELPHI2006_UP}
{$ifdef FPC}
  RequireDerivedFormResource := True;
{$endif FPC}
  Application.Title := 'ChakraCore WebAssembly Sample';
  Application.Initialize;
  Application.CreateForm(TDataModuleMain, DataModuleMain);
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
