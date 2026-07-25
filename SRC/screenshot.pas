unit ScreenShot;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ComCtrls, ExtCtrls,prologix,hp3577,serial,misc_function;

type

  { TfrmScreenShot }

  TfrmScreenShot = class(TForm)
    btnScreenShot: TButton;
    btnSaveScreenShot: TButton;
    PaintBox1: TPaintBox;
    ProgressBar1: TProgressBar;
    StaticText1: TStaticText;
    procedure btnSaveScreenShotClick(Sender: TObject);
    procedure btnScreenShotClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);

  private
      procedure DrawHPGL(TargetCanvas: TCanvas; TargetHeight: Integer);
  public

  end;

var
  frmScreenShot: TfrmScreenShot;

implementation

{$R *.lfm}

{ TfrmScreenShot }

procedure TfrmScreenShot.FormCreate(Sender: TObject);
begin
staticText1.Caption:='This is used to make a screen shot of the machine By pressing the button at desktop folder'+
'will create a hpgl file with the screenshot of the machine as is';
self.Height:=240;
self.Width:=319;
btnScreenShot.Visible:=True;
   progressbar1.Visible:=True;
   staticText1.Visible:=True;
   PaintBox1.Visible:=False;
   btnSaveScreenShot.Visible:=False;
end;

procedure TfrmScreenShot.FormResize(Sender: TObject);
begin
   if self.WindowState=wsMaximized then
  begin
   btnScreenShot.Visible:=False;
   progressbar1.Visible:=False;
   staticText1.Visible:=False;
   PaintBox1.Visible:=true;
   btnSaveScreenShot.Visible:=True;
  end;
end;



procedure TfrmScreenShot.btnScreenShotClick(Sender: TObject);
const Total_Size=8000;
var
  response,chunk:String;
  LastDataTime: QWord;
begin
   self.Height:=240;
   self.Width:=319;
   progressbar1.Smooth:=True;
   response:='';chunk:='';
   if prologix.config then
   if prologix.isopen then
   begin
    try
    //initalize as fast as possible
     prologix.Write_Data('BD0;FM1;DCH');
     prologix.Write_Data('PLA;TKM'); //request plot all and wait to make a measurement
     LastDataTime := GetTickCount64;
     repeat
      Application.ProcessMessages;
      chunk:=serials.LazSerial1.ReadData;
      if chunk<>'' then 
      begin
        Response:=Response+chunk;
        LastDataTime := GetTickCount64;
      end;
      sleep(sleep_time);
      if progressbar1.Position<90 then
      progressbar1.Position:=Round((Length(Response) / Total_Size) * 90);
     until (pos('<0>',Response)>0) or 
           ((Response = '') and (GetTickCount64 - LastDataTime > 60000)) or 
           ((Response <> '') and (GetTickCount64 - LastDataTime > 3000));
     //if file exist delete it
     if FileExists(GetUserDir + 'Desktop' + PathDelim + 'Screen.hpgl')
     then DeleteFile(GetUserDir + 'Desktop' + PathDelim +  'Screen.hpgl');
      //write to file
      WriteToFile('Screen',Response);
    if FileExists(GetUserDir + 'Desktop' + PathDelim + 'Screen.csv') //if file saved
    //then Rename The File.
    then RenameFile(GetUserDir + 'Desktop' + PathDelim + 'Screen.csv',GetUserDir + 'Desktop' + PathDelim +  'Screen.hpgl');
    if progressbar1.Position<100 then progressbar1.Position:=100;
    Except
      on E:Exception do
      ShowMessage(E.Message);
    end;
   end;
   frmScreenShot.WindowState:=wsMaximized;
   DrawHPGL(PaintBox1.Canvas, PaintBox1.Height);
   PaintBox1.Invalidate;//redraw it.
end;

procedure TfrmScreenShot.btnSaveScreenShotClick(Sender: TObject);
var
  Bitmap: TBitmap;
begin

    Bitmap := TBitmap.Create;
    try
      Bitmap.Width := PaintBox1.Width;
      Bitmap.Height := PaintBox1.Height;

      // Draw the bitmat
      DrawHPGL(Bitmap.Canvas, Bitmap.Height);
     //save the file Dialog
      Bitmap.SaveToFile(GetUserDir + 'Desktop' + PathDelim +  'ScreenShot');
      ShowMessage('All Done');
    finally
      Bitmap.Free;
    end;
  end;
procedure TfrmScreenShot.DrawHPGL(TargetCanvas: TCanvas; TargetHeight: Integer);
var
  FileLines: TStringList;
  FullText, Block, Cmd, ParamX, ParamY: String;
  PosSemi, PosComma, X, Y: Integer;
  PenDown: Boolean;
begin
    if not FileExists(GetUserDir + 'Desktop' + PathDelim +  'Screen.hpgl') then Exit;

  // Make it clear
  TargetCanvas.Brush.Color := clWhite;
  TargetCanvas.FillRect(Rect(0, 0, PaintBox1.Width, PaintBox1.Height));

  FileLines := TStringList.Create;
  try
    FileLines.LoadFromFile(GetUserDir + 'Desktop' + PathDelim +  'Screen.hpgl');
    FullText := UpperCase(FileLines.Text);
    PenDown := False;

    // Read The String and remove the ;
    while Length(FullText) > 0 do
    begin
      PosSemi := Pos(';', FullText);
      if PosSemi = 0 then Break;

      Block := Trim(Copy(FullText, 1, PosSemi - 1));
      Delete(FullText, 1, PosSemi);

      if Length(Block) < 2 then Continue;
      Cmd := Copy(Block, 1, 2); // The fisrt 2 letters are the command not care
      Delete(Block, 1, 2);      // The leftover is the X.Y
      // check Instrunction
      if Cmd = 'PU' then PenDown := False; //Pen Up not writing
      if Cmd = 'PD' then PenDown := True; //Pen Down write

      // if is label then print it (LB)
      if Cmd = 'LB' then
      begin
        Block := StringReplace(Block, #3, '', [rfReplaceAll]); // Remove ETX
        TargetCanvas.TextOut(TargetCanvas.PenPos.X, TargetCanvas.PenPos.Y, Block);
      end;

      // Draw the line if exists
      PosComma := Pos(',', Block);
      if PosComma > 0 then
      begin
        ParamX := Copy(Block, 1, PosComma - 1);
        ParamY := Copy(Block, PosComma + 1, Length(Block));

        X := StrToIntDef(Trim(ParamX), 0);
        Y := StrToIntDef(Trim(ParamY), 0);

        // Ration /20 and rotate the axis
        X := Round(X / 20) + 20;
        Y := TargetHeight - Round(Y / 20) - 20;

        if PenDown then TargetCanvas.LineTo(X, Y) else TargetCanvas.MoveTo(X, Y);
      end;
    end;
  finally
    FileLines.Free;
  end;
end;

end.

