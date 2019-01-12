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

program ChakraCoreTestsUI;

{$include ..\src\common.inc}

{$ifdef FPC}
  {$apptype GUI}
{$endif}

uses
  SysUtils, Classes,
{$ifdef FPC}
  Interfaces, Forms, Graphics, GuiTestRunner,     
{$endif}
{$ifdef DELPHI}
  TestFramework, GUITestRunner,
{$endif}
  Compat, Test_ChakraCore, Test_Classes, ChakraCoreVersion;

{$R *.res}

begin
{$ifdef FPC}
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
{$ifdef WINDOWS}
  TestRunner.XMLSynEdit.Font.Name := 'Consolas';
{$endif}
{$ifdef LINUX}
  TestRunner.XMLSynEdit.Font.Name := 'Liberation Mono';
{$endif}
{$ifdef DARWIN}
  TestRunner.XMLSynEdit.Font.Name := 'Menlo';
{$endif}
  TestRunner.XMLSynEdit.Font.Quality := fqCleartype;

  TestRunner.MemoLog.Append(Format('%s %s', [ExtractFileName(ParamStr(0)), GetExeFileVersionString]));
  TestRunner.MemoLog.Append(Format('Built with %s', [GetBuildInfoString]));
  TestRunner.MemoLog.Append(Format('Chakra Core version: %d.%d.%d', [CHAKRA_CORE_MAJOR_VERSION, CHAKRA_CORE_MINOR_VERSION, CHAKRA_CORE_PATCH_VERSION]));
  Application.Run;
{$endif}

{$ifdef DELPHI}
  with TGUITestRunner.Create(nil) do
  begin
    try
      ErrorMessageRTF.Lines.Add(Format('%s %s', [ExtractFileName(ParamStr(0)), GetExeFileVersionString]));
      ErrorMessageRTF.Lines.Add(Format('Built with %s', [GetBuildInfoString]));
      ErrorMessageRTF.Lines.Add(Format('Chakra Core version: %d.%d.%d', [CHAKRA_CORE_MAJOR_VERSION, CHAKRA_CORE_MINOR_VERSION, CHAKRA_CORE_PATCH_VERSION]));
      Suite := registeredTests;
      ShowModal;
    finally
      Free;
    end;
  end;
{$endif}
end.
