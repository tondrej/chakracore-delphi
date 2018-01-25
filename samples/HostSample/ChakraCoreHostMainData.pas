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

unit ChakraCoreHostMainData;

interface

{$include common.inc}

uses
{$ifdef LINUX}
{$ifdef FPC}
  cwstring,
{$endif}
{$endif}
{$ifdef WINDOWS}
  Windows,
{$endif}
  SysUtils, Classes,
{$ifdef HAS_WIDESTRUTILS}
  WideStrUtils,
{$endif}
  Compat, ChakraCoreUtils, ChakraCoreClasses, Console;

type
  TDataModuleMain = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FBaseDir: UnicodeString;
    FConsole: TConsole;
    FContext: TChakraCoreContext;
    FRuntime: TChakraCoreRuntime;
    FUseAnsiColors: Boolean;

    procedure ConsolePrint(Sender: TObject; const Text: UnicodeString; Level: TInfoLevel = ilNone);
    procedure ContextLoadModule(Sender: TObject; Module: TChakraModule);
    procedure ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
  public
    procedure Execute(const ScriptFileNames: array of UnicodeString);

    property BaseDir: UnicodeString read FBaseDir;
    property Console: TConsole read FConsole;
    property Context: TChakraCoreContext read FContext;
    property Runtime: TChakraCoreRuntime read FRuntime;
    property UseAnsiColors: Boolean read FUseAnsiColors write FUseAnsiColors;
  end;

implementation

{$R *.dfm}

function LoadFile(const FileName: UnicodeString): UnicodeString;
var
  FileStream: TFileStream;
  S: UTF8String;
begin
  Result := '';

  FileStream := TFileStream.Create(FileName, fmOpenRead);
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

procedure TDataModuleMain.ConsolePrint(Sender: TObject; const Text: UnicodeString; Level: TInfoLevel);
const
  StartBlocks: array[TInfoLevel] of RawByteString = ('', #$1b'[32;1m', #$1b'[33;1m', #$1b'[31;1m');
  EndBlocks: array[Boolean] of RawByteString = ('', #$1b'[0m');
{$ifdef WINDOwS}
  BackgroundMask = $F0;
  TextColors: array[TInfoLevel] of Word = (0, FOREGROUND_GREEN or FOREGROUND_INTENSITY,
    FOREGROUND_GREEN or FOREGROUND_RED or FOREGROUND_INTENSITY, FOREGROUND_RED or FOREGROUND_INTENSITY);
var
  Info: TConsoleScreenBufferInfo;
  S: UTF8String;
{$endif}
begin
  S := UTF8Encode(Text);
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

procedure TDataModuleMain.ContextLoadModule(Sender: TObject; Module: TChakraModule);
var
  ModuleFileName: UnicodeString;
begin
  ModuleFileName := IncludeTrailingPathDelimiter(FBaseDir) + ChangeFileExt(Module.Name, '.js');
  if FileExists(ModuleFileName) then
  begin
    Module.Parse(LoadFile(ModuleFileName));
    Module.URL := WideFormat('file://%s/%s', [ChangeFileExt(ExtractFileName(ParamStr(0)), ''), ChangeFileExt(Module.Name, '.js')]);
  end;
end;

procedure TDataModuleMain.ContextNativeObjectCreated(Sender: TObject; NativeObject: TNativeObject);
begin
  if NativeObject is TConsole then
    TConsole(NativeObject).OnPrint := ConsolePrint;
end;

procedure TDataModuleMain.DataModuleCreate(Sender: TObject);
begin
  try
    FRuntime := TChakraCoreRuntime.Create([ccroEnableExperimentalFeatures, ccroDispatchSetExceptionsToDebugger]);
    FContext := TChakraCoreContext.Create(FRuntime);
    FContext.OnLoadModule := ContextLoadModule;
    FContext.OnNativeObjectCreated := ContextNativeObjectCreated;
    FContext.Activate;

    TConsole.Project('Console');

    FConsole := TConsole.Create;
    FConsole.OnPrint := ConsolePrint;
    JsSetProperty(FContext.Global, 'console', FConsole.Instance);
  except
    FConsole := nil;
    FreeAndNil(FContext);
    FreeAndNil(FRuntime);
    raise;
  end;
end;

procedure TDataModuleMain.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FConsole);
  FConsole := nil;
  FreeAndNil(FContext);
  FreeAndNil(FRuntime);
end;

procedure TDataModuleMain.Execute(const ScriptFileNames: array of UnicodeString);
var
  I: Integer;
begin
  for I := Low(ScriptFileNames) to High(ScriptFileNames) do
  begin
    FBaseDir := ExtractFilePath(ScriptFileNames[I]);
    FContext.RunScript(LoadFile(ScriptFilenames[I]), UnicodeString(ExtractFileName(ScriptFileNames[I])));
  end;
end;

end.
