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
    procedure PaintBox1Paint(Sender: TObject);

  private
      procedure DrawHPGL(TargetCanvas: TCanvas; TargetWidth, TargetHeight: Integer);
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


  procedure TfrmScreenShot.PaintBox1Paint(Sender: TObject);
begin
  DrawHPGL(PaintBox1.Canvas, PaintBox1.Width,PaintBox1.Height);
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
  // DrawHPGL(PaintBox1.Canvas, PaintBox1.Width,PaintBox1.Height);
    Application.ProcessMessages;
  PaintBox1.Invalidate; //redraw it.
end;

procedure TfrmScreenShot.btnSaveScreenShotClick(Sender: TObject);
var
   Bitmap: TBitmap;
begin

    Bitmap:= TBitmap.create;
    try
      Bitmap.Width := PaintBox1.Width;
    Bitmap.Height := PaintBox1.Height;


      // Draw the bitmat
      DrawHPGL(Bitmap.Canvas, Bitmap.Width,bitmap.Height);
     //save the file Dialog
      Bitmap.SaveToFile(GetUserDir + 'Desktop' + PathDelim +  'ScreenShot.bmp');
      ShowMessage('All Done');
    finally
      Bitmap.Free;
    end;
  end;

procedure TfrmScreenShot.DrawHPGL(TargetCanvas: TCanvas; TargetWidth, TargetHeight: Integer);
var
  FileLines: TStringList;
  FullText, Cmd, Block, ParamX, ParamY: String;
  X, Y, PosComma, i: Integer;
  PenDown: Boolean;
  MaxHPGL_X, MaxHPGL_Y: Integer;
  Ch: Char;

  // center the image variables
  UsableWidth, UsableHeight: Integer;
  ScaleX, ScaleY, Scale: Double;
  OffsetX, OffsetY, Padding: Integer;

  // vertical
  FontAngle: Integer;

  // coloring
  MachineGreen, SignalColor: TColor;
begin
  if not FileExists(GetUserDir + 'Desktop' + PathDelim + 'Screen.hpgl') then Exit;

  MaxHPGL_X := 2144;
  MaxHPGL_Y := 2047;

  //coloers
  MachineGreen := RGBToColor(0, 160, 0);
  SignalColor := clBlack; // black for letters and graph

  // 40 pixel as limit
  Padding := 40;
  UsableWidth := TargetWidth - (Padding * 2);
  UsableHeight := TargetHeight - (Padding * 2);

  // scale for free space
  ScaleX := UsableWidth / MaxHPGL_X;
  ScaleY := UsableHeight / MaxHPGL_Y;
  if ScaleX < ScaleY then Scale := ScaleX else Scale := ScaleY;

  // center with the 40pixel width
  OffsetX := Round((UsableWidth - (MaxHPGL_X * Scale)) / 2) + Padding;
  OffsetY := Round((UsableHeight - (MaxHPGL_Y * Scale)) / 2) + Padding;

  // prepare the camvas
  TargetCanvas.Brush.Color := clWhite;
  TargetCanvas.FillRect(Rect(0, 0, TargetWidth, TargetHeight));
  TargetCanvas.Pen.Color := SignalColor;
  TargetCanvas.Pen.Width := 1;

  TargetCanvas.Font.Name := 'Arial';
  TargetCanvas.Font.Size := 12;
  TargetCanvas.Font.Color := SignalColor;
  TargetCanvas.Brush.Style := bsClear;
  FontAngle := 0;

  FileLines := TStringList.Create;
  try
    FileLines.LoadFromFile(GetUserDir + 'Desktop' + PathDelim + 'Screen.hpgl');
    FullText := FileLines.Text;

    PenDown := False;
    i := 1;

    while i <= Length(FullText) do
    begin
      if FullText[i] in [#13, #10, ' '] then
      begin
        Inc(i);
        Continue;
      end;

      if i + 1 > Length(FullText) then Break;
      Cmd := UpperCase(Copy(FullText, i, 2));
      Inc(i, 2);

      // 1. pen / color (SP)
      if Cmd = 'SP' then
      begin
        Block := '';
        while (i <= Length(FullText)) and (FullText[i] <> ';') do
        begin
          Block := Block + FullText[i];
          Inc(i);
        end;
        if i <= Length(FullText) then Inc(i); // skip ';'

        Block := Trim(Block);
        // SP 1 is the graph or text, SP 2 is the Grid
        if Block = '2' then
          TargetCanvas.Pen.Color := MachineGreen
        else
          TargetCanvas.Pen.Color := SignalColor;

        Continue;
      end;

      // 2. text direction (DI)
      if Cmd = 'DI' then
      begin
        Block := '';
        while (i <= Length(FullText)) and (FullText[i] <> ';') do
        begin
          Block := Block + FullText[i];
          Inc(i);
        end;
        if i <= Length(FullText) then Inc(i);

        PosComma := Pos(',', Block);
        if PosComma > 0 then
        begin
          ParamX := Trim(Copy(Block, 1, PosComma - 1));
          if StrToIntDef(ParamX, 0) = 0 then FontAngle := 900 else FontAngle := 0;
        end;
        Continue;
      end;

      // 3.  LABEL (LB)
      if Cmd = 'LB' then
      begin
        Block := '';
        while i <= Length(FullText) do
        begin
          Ch := FullText[i];
          Inc(i);
          if Ch = #3 then Break;
          Block := Block + Ch;
        end;

        TargetCanvas.Font.Orientation := FontAngle;
        TargetCanvas.TextOut(TargetCanvas.PenPos.X, TargetCanvas.PenPos.Y, Block);
        TargetCanvas.Font.Orientation := 0;
        Continue;
      end;

      Block := '';
      while i <= Length(FullText) do
      begin
        Ch := FullText[i];
        Inc(i);
        if Ch = ';' then Break;
        Block := Block + Ch;
      end;
      Block := Trim(UpperCase(Block));

      if Cmd = 'PU' then PenDown := False;
      if Cmd = 'PD' then PenDown := True;

      // 4. draw and moce  (PA and CP for  MARKER)
      if (Cmd = 'PA') or (Cmd = 'PU') or (Cmd = 'PD') or (Cmd = 'CP') then
      begin
        while Length(Block) > 0 do
        begin
          PosComma := Pos(',', Block);
          if PosComma = 0 then Break;

          ParamX := Trim(Copy(Block, 1, PosComma - 1));
          Delete(Block, 1, PosComma);
          Block := Trim(Block);

          PosComma := Pos(',', Block);
          if PosComma > 0 then
          begin
            ParamY := Trim(Copy(Block, 1, PosComma - 1));
            Delete(Block, 1, PosComma);
            Block := Trim(Block);
          end
          else
          begin
            ParamY := Block;
            Block := '';
          end;

          //  CP: marker red (dot)
          if Cmd = 'CP' then
          begin
            // red color
            TargetCanvas.Brush.Color := clRed;
            TargetCanvas.FillRect(Rect(TargetCanvas.PenPos.X - 2, TargetCanvas.PenPos.Y - 2,
                                       TargetCanvas.PenPos.X + 3, TargetCanvas.PenPos.Y + 3));
            TargetCanvas.Brush.Style := bsClear; // return to the transparent
            Break; // in the end break
          end
          else
          begin
            X := StrToIntDef(ParamX, 0);
            Y := StrToIntDef(ParamY, 0);
            X := Round(X * Scale) + OffsetX;
            Y := TargetHeight - Round(Y * Scale) - OffsetY;
          end;

          if (Cmd = 'PD') or PenDown then
            TargetCanvas.LineTo(X, Y)
          else
            TargetCanvas.MoveTo(X, Y);

          if Cmd = 'PD' then PenDown := True;
          if Cmd = 'PU' then PenDown := False;
        end;
      end;
    end;
  finally
    FileLines.Free;
   end;
end;




end.

