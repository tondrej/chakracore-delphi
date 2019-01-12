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

program ChakraCoreTests;

{$include ..\src\common.inc}

{$ifdef FPC}
  {$macro ON}
{$endif}

{$ifdef CONSOLE_TESTRUNNER}
  {$apptype CONSOLE}
{$endif}

uses
  SysUtils, Classes,
{$ifdef FPC}
  consoletestrunner, fpcunitreport, plaintestreport,
{$endif}
{$ifdef DELPHI}
  TextTestRunner,
{$endif}
  Compat, ChakraCoreVersion, Test_ChakraCore, Test_Classes;

{$R *.res}

{$ifdef FPC}
var
  Application: TTestRunner;
{$endif}

begin
  Writeln(Format('%s %s', [ExtractFileName(ParamStr(0)), GetExeFileVersionString]));
  Writeln(Format('Built with %s', [GetBuildInfoString]));
  Writeln(Format('Chakra Core version: %d.%d.%d', [CHAKRA_CORE_MAJOR_VERSION, CHAKRA_CORE_MINOR_VERSION, CHAKRA_CORE_PATCH_VERSION]));
  Writeln;

{$ifdef FPC}
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Run;
  finally
    Application.Free;
  end;
{$endif}

{$ifdef DELPHI}
  RunRegisteredTests;
{$endif}
end.
