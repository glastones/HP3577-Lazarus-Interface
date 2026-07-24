unit show;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  TAGraph, TASeries, TATransformations, Serial,prologix;

type

  { TfrmShow }

  TfrmShow = class(TForm)
    btnSaveJpg: TButton;
    Chart1: TChart;
    Chart1LineSeries1: TLineSeries;
    Timer1: TTimer;

     procedure btnSaveJpgClick(Sender: TObject);
     procedure FormActivate(Sender: TObject);
     procedure FormCreate(Sender: TObject);
     function read_data:Boolean;
     procedure Timer1Timer(Sender: TObject);
	procedure init;
        procedure SaveChartAsJPG(AChart: TChart; const FileName: string);
  private
    function ExtractValue(src, key : string) : Double;
  public
      currentline:String;
initialize:boolean;
FHigh,Flow:Real;
  end;

var
  frmShow: TfrmShow;

implementation


{$R *.lfm}
 function TfrmShow.read_data: Boolean;
var
  packet: string;
  LineTokens: TStringList;
  ValX, ValY: Double;
  Step: Double;
  i: Integer;
  guard: Integer;
  FS: TFormatSettings;
  complete:Boolean;
begin
  Result := False;
  guard := 0; complete:=False;

  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';

  LineTokens := TStringList.Create;

  try
    Chart1LineSeries1.Clear;

    ValX := Flow;
    Step := (FHigh - Flow) / 401;

    Chart1LineSeries1.BeginUpdate;  //optimized
    try

      repeat
        packet := Serials.LazSerial1.ReadData;

        if packet <> '' then
        begin
          packet := trim(StringReplace(packet, '<0>', '', [rfReplaceAll]));
         if pos(#13,packet)>0 then complete:=True;
          LineTokens.Clear;
          ExtractStrings([','], [], PChar(packet), LineTokens);

          for i := 0 to LineTokens.Count - 1 do
          begin
            try
              ValY := StrToFloat(Trim(LineTokens[i]), FS);

              Chart1LineSeries1.AddXY(ValX, ValY);

              ValX := ValX + Step;

            except
            end;
          end;
        end;

        if  complete then
        begin
        Serials.LazSerial1.SynSer.Purge;
       Serials.LazSerial1.WriteData('DT1' + sLineBreak);
        end;
        Sleep(10);
        Inc(guard);

      // FIX: bound the loop. Without this, if the instrument never sends a CR
      // (#13) the UI would freeze permanently. ~1000 * 10ms = ~10s ceiling.
      until (Pos(#13, packet) > 0) or (guard > 1000);

     finally
      Chart1LineSeries1.EndUpdate;
    end;

    Result := True;

  finally
    LineTokens.Free;
  end;
end;
procedure TfrmShow.Timer1Timer(Sender: TObject);
begin
   Timer1.Enabled := False;

  try
    if read_data then
      frmShow.Caption := 'Complete';
  finally
    Timer1.Enabled := True;
  end;
end;



 function  TfrmShow.ExtractValue(src, key : string) : Double;
 var
  Fields: TStringList;
  FieldText: string;
  i: Integer;
  begin
  Result := 0;
  Fields := TStringList.Create;
  try
    // coma delimiter
    Fields.Delimiter := ',';
    Fields.StrictDelimiter := True;
    Fields.DelimitedText := src;
                     //cheak each field
    for i := 0 to Fields.Count - 1 do
    begin
        FieldText := Trim(Fields[i]);

      // is the field the correct one?
      if Pos(Key, FieldText) = 1 then
      begin
        // if yes remove the Hz and , and spaces
        FieldText := StringReplace(FieldText, Key, '', []);
        FieldText := StringReplace(FieldText, 'Hz', '', [rfReplaceAll]);
        FieldText := StringReplace(FieldText, ' ', '', [rfReplaceAll]);
        if TryStrToFloat(FieldText, Result) then
          Exit;
      end;
    end;
  finally
    Fields.Free;
  end;
end;
procedure TfrmShow.FormActivate(Sender: TObject);
begin
if prologix.config then begin
timer1.Enabled:=False;
Timer1.Interval:=1000;
     if  not serials.LazSerial1.Active then serials.connect_dialog;
        init;
   frmshow.top:=(Screen.DesktopHeight-frmshow.Height) div 2;
   frmshow.left:=(screen.DesktopWidth-frmshow.Width)div 2;
    read_data;
    timer1.Enabled:=True;

      end;
                             end;
procedure TfrmShow.btnSaveJpgClick(Sender: TObject);
begin
  SaveChartAsJPG(Chart1, GetUserDir + 'Desktop' + PathDelim + 'Chart.jpg');
end;
procedure TfrmShow.FormCreate(Sender: TObject);
begin
  initialize:=false;
  init;
end;

procedure  TfrmShow.init;
var 
step:Real;
c:char;
begin
step:=0;FHigh:=0;Flow:=0;currentLine:='';
initialize:=false;
c:=DefaultFormatSettings.DecimalSeparator;
  //if  not serials.LazSerial1.Active then serials.connect_dialog;

  // Initialize measurement parameters
Serials.LazSerial1.SynSer.Purge; //clear the RS232
Serials.LazSerial1.WriteData('BD0;'+'FM1;'+'DCH'+sLineBreak);
// BUG FIX: Wait for DCH response to arrive. Serial is asynchronous and 100ms sleep may not be enough.
  Sleep(500);
  CurrentLine := Serials.LazSerial1.ReadData;
  CurrentLine:=StringReplace(CurrentLine,'.',c,[rfReplaceAll]);
  if not (CurrentLine.IsEmpty or String.IsNullOrEmpty(CurrentLine) or String.IsNullOrWhiteSpace(CurrentLine)) then
  begin
    flow:=extractValue(CurrentLine,'START ');
    Fhigh:=ExtractValue(CurrentLine,'STOP ');
  end;
  if (flow=0) and (Fhigh=0) then
  begin
    flow:=ExtractValue(CurrentLine,'CENTER ');
    FHigh:=ExtractValue(CurrentLine,'SPAN ');
    step:=FHigh/2;
    Fhigh:=flow+Step;
    Flow:=flow-Step;
  end;
Serials.LazSerial1.SynSer.Purge;//Clear The RS232
initialize:=True;
Serials.LazSerial1.WriteData('DT1'+sLineBreak);
end;

procedure TfrmShow.SaveChartAsJPG(AChart: TChart; const FileName: string);
var
  Bmp: TBitmap;
  Jpg: TJPEGImage;
begin
  Bmp := TBitmap.Create;
  Jpg := TJPEGImage.Create;
  try
    Bmp.SetSize(AChart.Width, AChart.Height);
    AChart.PaintOnCanvas(Bmp.Canvas, Rect(0, 0, Bmp.Width, Bmp.Height));

    Jpg.Assign(Bmp);
    Jpg.CompressionQuality := 90;
    Jpg.SaveToFile(FileName);
  finally
    Jpg.Free;
    Bmp.Free;
  end;
end;

             end.
