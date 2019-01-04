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

unit WasmMainForm;

interface

{$include common.inc}

uses
{$ifdef FPC}
  LCLIntf, LCLType, LMessages,
{$else}
  Windows,
{$endif}
  SysUtils, Variants, Classes, Types, Messages,
  Graphics, Controls, Forms, Dialogs, StdCtrls, ExtCtrls, ToolWin, ComCtrls, ActnList, ImgList;

const
  Dimension = 50;

  WM_CONSOLELOG = WM_USER + 1;

type

  TWMConsoleLog = record
    Msg: Cardinal;
{$ifdef CPU64}
    UnusedMsg: Cardinal;
{$endif CPU64}
    Text: PAnsiChar;
    Unusedl: NativeInt;
    Result: LRESULT;
  end;

  { TFormMain }

  TFormMain = class(TForm)
    ActionList: TActionList;
    ActionStartStop: TAction;
    ImageList: TImageList;
    MemoLog: TMemo;
    PaintBox: TPaintBox;
    ToolBar: TToolBar;
    ToolButtonStartStop: TToolButton;

    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);

    procedure ActionStartStopExecute(Sender: TObject);
    procedure ActionStartStopUpdate(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
  private
    FGame: array[0..Dimension - 1, 0..Dimension - 1] of Boolean;

    procedure ApplicationIdle(Sender: TObject; var Done: Boolean);
    procedure WMConsoleLog(var Message: TWMConsoleLog); message WM_CONSOLELOG;
  public
    procedure FillRect(X, Y, W, H: Integer; const Style: string);
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  Compat, ChakraCore, ChakraCoreVersion, ChakraCoreUtils,
  WasmMainData;

procedure TFormMain.FillRect(X, Y, W, H: Integer; const Style: string);
var
  I, J: Integer;
  CellValue: Boolean;
begin
  CellValue := Style = 'green';

  if not CellValue and (W = Dimension) and (H = Dimension) then
  begin
    FillChar(FGame, SizeOf(FGame), 0);
    Exit;
  end;
  
  for I := X to X + W - 1 do
    for J := Y to Y + H - 1 do
      FGame[I, J] := CellValue;

{$ifndef LINUX}
  PaintBox.Invalidate;
{$endif !LINUX}
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;
  DataModuleMain.Active := False;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  PaintBox.Width := ClientWidth - 8;
  MemoLog.Width := ClientWidth - 8;
  DoubleBuffered := True;
  Caption := Application.Title;
{$ifdef LINUX}
  Application.OnIdle := ApplicationIdle;
{$endif LINUX}

  MemoLog.Lines.Add(Format('%s %s', [ExtractFileName(ParamStr(0)), GetExeFileVersionString]));
  MemoLog.Lines.Add(Format('Built with %s', [GetBuildInfoString]));
  MemoLog.Lines.Add(Format('Chakra Core version: %d.%d.%d', [CHAKRA_CORE_MAJOR_VERSION, CHAKRA_CORE_MINOR_VERSION, CHAKRA_CORE_PATCH_VERSION]));
  MemoLog.Lines.Add('');
end;

procedure TFormMain.ActionStartStopExecute(Sender: TObject);
begin
  DataModuleMain.Active := not DataModuleMain.Active;
end;

procedure TFormMain.ActionStartStopUpdate(Sender: TObject);
const
  StartStopCaptions: array[Boolean] of string = ('Start', 'Stop');
  StartStopImageIndexes: array[Boolean] of Integer = (0, 1);
var
  Action: TAction absolute Sender;
begin
  Action.Caption := StartStopCaptions[DataModuleMain.Active];
  Action.Hint := StartStopCaptions[DataModuleMain.Active];
  Action.ImageIndex := StartStopImageIndexes[DataModuleMain.Active];
end;

procedure TFormMain.PaintBoxPaint(Sender: TObject);
var
  PaintBox: TPaintBox absolute Sender;
  W, H, X, Y: Integer;
  R: TRect;
begin
  PaintBox.Canvas.Brush.Color := clBlack;
  PaintBox.Canvas.FillRect(PaintBox.ClientRect);

  PaintBox.Canvas.Brush.Color := clGreen;
  W := PaintBox.ClientWidth div Dimension;
  H := PaintBox.ClientHeight div Dimension;
  R := Rect(0, 0, W, H);
  for Y := 0 to Dimension - 1 do
  begin
    R.Left := 0;
    R.Right := W;
    for X := 0 to Dimension - 1 do
    begin
      if FGame[X, Y] then
        PaintBox.Canvas.FillRect(R);
      OffsetRect(R, W, 0);
    end;
    OffsetRect(R, 0, H);
  end;
end;

procedure TFormMain.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  PaintBox.Invalidate;
end;

procedure TFormMain.WMConsoleLog(var Message: TWMConsoleLog);
begin
  try
    // inherited;
    MemoLog.Lines.Add(Message.Text);
  finally
    StrDispose(Message.Text);
  end;
end;

end.
