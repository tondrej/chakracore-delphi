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

program ChakraCoreHostSample;

{$APPTYPE CONSOLE}

{$include common.inc}

uses
  {$ifdef FPC}{$ifdef UNIX}
  cthreads,
  {$endif}{$endif}
  SysUtils,
  Compat,
  ChakraCoreVersion, ChakraCoreUtils,
  ChakraCoreHostMainData in 'ChakraCoreHostMainData.pas' {DataModuleMain: TDataModule};

{$R *.res}

procedure ShowInfo;
begin
  Writeln(Format('%s %s', [ExtractFileName(ParamStr(0)), GetExeFileVersionString]));
  Writeln(Format('Built with %s', [GetBuildInfoString]));
  Writeln(Format('Chakra Core version: %d.%d.%d', [CHAKRA_CORE_MAJOR_VERSION, CHAKRA_CORE_MINOR_VERSION, CHAKRA_CORE_PATCH_VERSION]));
  Writeln;
end;

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

procedure Main;
var
  DataModule: TDataModuleMain;
begin
  ShowInfo;

  DataModule := TDataModuleMain.Create(nil);
  try
    DataModule.Execute(ParamStrings);
  finally
    DataModule.Free;
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
