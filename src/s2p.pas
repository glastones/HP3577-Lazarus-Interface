unit S2P;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  prologix, misc_function, serial, HP3577, TypInfo;
const
NUM_POINTS = 401;

type
   TGpibScalarArray = array[1..NUM_POINTS] of Double;
   TSParameterType = (S11,S11_deg,S21,S21_deg, S12,S12_deg, S22, S22_deg);

  { TfrmS2P }

  TfrmS2P = class(TForm)
    btnExport_S2P: TButton;
    cboUntis_StartFreq: TComboBox;
    cboUnits_StopFreq: TComboBox;
    ProgressBar: TProgressBar;
    StaticText1: TStaticText;
    txtStartFreq: TEdit;
    txtStopFreq: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure btnExport_S2PClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure txtStartFreqKeyPress(Sender: TObject; var Key: char);
    procedure txtStopFreqKeyPress(Sender: TObject; var Key: char);
  private
       function ParseGpibString(const GpibRawStr: string; var TargetArray: TGpibScalarArray): Boolean;
       function read_response(startFreq,stopFreq:Real;input:String):String;
  public
    end;

var
  frmS2P: TfrmS2P;

implementation

{$R *.lfm}

{ TfrmS2P }

procedure TfrmS2P.btnExport_S2PClick(Sender: TObject);
  var
 FileName:string;
 Instrument_Response:String;
  Param: TSParameterType;
 StartFreq, StopFreq: Double; // In Hz
 S11_dB,S11_deg: TGpibScalarArray;
 S21_dB,S21_deg: TGpibScalarArray;
 S12_dB,S12_deg: TGpibScalarArray;
 S22_dB,S22_deg: TGpibScalarArray;
 cal_S11_deg,cal_S11_db: TGpibScalarArray;
 cal_S22_deg,cal_S22_db: TGpibScalarArray;
 cal_S21_deg,cal_S21_db: TGpibScalarArray;
 cal_S12_deg,cal_S12_db: TGpibScalarArray;
 I: Integer;

  FS: TFormatSettings;
 CurrentFreq, FreqStep: Double;
 begin
   if FileExists( GetUserDir + 'Desktop' + PathDelim +  'Filter.s2p') then
DeleteFile(GetUserDir + 'Desktop' + PathDelim + 'Filter.s2p');//if file exist delete it
    FS := DefaultFormatSettings;
 FS.DecimalSeparator := '.';
  for i:=1 to NUM_POINTS do
  begin
    S11_dB[i]:=0;S11_deg[i]:=0;S21_dB[i]:=0;S21_deg[i]:=0;S12_dB[i]:=0;S12_deg[i]:=0;S22_dB[i]:=0;S22_deg[i]:=0;
    cal_S12_deg[i]:=0;cal_S22_deg[i]:=0;cal_S21_deg[i]:=0;cal_S11_deg[i]:=0;
    cal_S12_db[i]:=0;cal_S22_db[i]:=0;cal_S21_db[i]:=0;cal_S11_db[i]:=0;
  end;
   FileName:='S2P';

 ShowMessage('Please Wait as the procedure starts when you press to OK button');

  try
    StartFreq:=StrToFloat(txtStartFreq.text,FS);
    StopFreq:=StrToFloat(txtStopFreq.text,FS);
    case cboUntis_StartFreq.ItemIndex of
    1:StartFreq:=StartFreq*1000;
    2:StartFreq:=StartFreq*1000000;
    end;
    case cbounits_StopFreq.ItemIndex of
    1:StopFreq:=StopFreq*1000;
    2:StopFreq:=StopFreq*1000000;
    end;
     if (startFreq<5) or (startFreq>=200000000) or (startFreq>StopFreq) then
     begin
       ShowMessage('Error in Start Frequency. Try Again. Enter Correct number');
       txtStartFreq.Text:='';
       txtStartFreq.SetFocus;
       Exit;
     end;
      if (stopFreq<5) or (stopFreq>=200000000) or (stopFreq<StartFreq) then
     begin
        ShowMessage('Error in Stop Frequency. Try Again. Enter Correct number');
       txtStopFreq.Text:='';
       txtStopFreq.SetFocus;
       Exit;
     end;
    Except
      on E: EConvertError do
    ShowMessage('Invalid Number');
      on E:Exception do
      ShowMessage(E.Message);
    end;


   progressbar.BarShowText:=true;
   progressbar.Smooth:=True;
   progressbar.Step:=Round(progressbar.Max/10);
   progressbar.Visible:=True;
   staticText1.Visible:=True;

   ShowMessage ('Calibration routine Starts leave port open');

     //cal_S11
     begin
     ShowMessage('Leave the ports open S11,S22');
     instrument_Response:=read_response(StartFreq,stopFreq,'S11');
     if not ParseGpibString(Instrument_Response,cal_S11_db) then
     begin
     ShowMessage('Error parsing S11 data. Export aborted.');
      Exit;
     end
     else progressbar.Position:=progressbar.Position+progressbar.Step;
      //cal_S11 deg
     instrument_Response:=read_response(StartFreq,stopFreq,'S11_deg');
     if not ParseGpibString(Instrument_Response, cal_S11_deg) then
     begin
     ShowMessage('Error parsing S11 Phase data. Export aborted.');
      Exit;
     end;
     //call_S22
      instrument_Response:=read_response(StartFreq,stopFreq,'S22');
      if not ParseGpibString(Instrument_Response,cal_S22_db) then
     begin
     ShowMessage('Error parsing S22 data. Export aborted.');
      Exit;
     end
      else progressbar.Position:=progressbar.Position+progressbar.Step;
       //s22 deg
        instrument_Response:=read_response(StartFreq,stopFreq,'S22_deg');
      if not ParseGpibString(Instrument_Response,cal_S22_DEG) then begin
     ShowMessage('Error parsing S22 Phase data. Export aborted.');
      Exit;  end
      else progressbar.Position:=progressbar.Position+progressbar.Step;
      //cal_S21
     ShowMessage('Install Short - Trhu ');
       instrument_Response:=read_response(StartFreq,stopFreq,'S21');
     if not ParseGpibString(Instrument_Response,cal_S21_db) then
     begin
     ShowMessage('Error parsing S21  data. Export aborted.');
      Exit;
      end;  //cal_S21_Deg
      instrument_Response:=read_response(StartFreq,stopFreq,'S21_deg');
     if not ParseGpibString(Instrument_Response,cal_S21_DEG) then begin
      ShowMessage('Error parsing S21 Phase data. Export aborted.');
      Exit; end else progressbar.Position:=progressbar.Position+progressbar.Step;
      //cal_S12
       instrument_Response:=read_response(StartFreq,stopFreq,'S12');
     if not ParseGpibString(Instrument_Response,cal_S12_db) then
     begin
 ShowMessage('Error parsing S12 pahse data. Export aborted.');
      Exit;
     end
     else progressbar.Position:=progressbar.Position+progressbar.Step;
     //s12 deg
      instrument_Response:=read_response(StartFreq,stopFreq,'S12_deg');
      if not ParseGpibString(Instrument_Response,cal_S12_DEG) then begin
         ShowMessage('Error parsing S12 Phase data. Export aborted.');
      Exit; end else  progressbar.Position:=progressbar.Position+progressbar.Step;
      end;

   ShowMessage ('Calibration Routine Ended. Place the filter and we start now.');

      for Param := Low(TSParameterType) to High(TSParameterType) do
  begin

     instrument_Response:=read_response(StartFreq,stopFreq,GetEnumName(TypeInfo(TSParameterType),ord(Param)));
     case  GetEnumName(TypeInfo(TSParameterType),ord(Param))of
     'S11'://S11
     begin
     if not ParseGpibString(Instrument_Response,S11_DB) then
     begin
 ShowMessage('Error parsing S11  data. Export aborted.');
      Exit;end else progressbar.Position:=progressbar.Position+progressbar.Step; end;
     'S21'://S21
   begin
     if not ParseGpibString(Instrument_Response,S21_DB) then
     begin
 ShowMessage('Error parsing S21  data. Export aborted.');
      Exit;
      end;end;
     'S12'://S12
     begin
     if not ParseGpibString(Instrument_Response,S12_DB) then
     begin
 ShowMessage('Error parsing S21  data. Export aborted.');
      Exit; end else progressbar.Position:=progressbar.Position+progressbar.Step;end;
     'S22'://S22
       begin
     if not ParseGpibString(Instrument_Response,S22_DB) then
     begin
 ShowMessage('Error parsing S21 data. Export aborted.');
      Exit;  end else progressbar.Position:=progressbar.Position+progressbar.Step;end;
    'S11_deg': //S11 deg
     begin
     if not ParseGpibString(Instrument_Response,S11_DEG) then
     begin
 ShowMessage('Error parsing S11 Phase data. Export aborted.');
      Exit;  end;end;
    'S22_deg': //s22 deg
     begin
     if not ParseGpibString(Instrument_Response,S22_DEG) then begin
 ShowMessage('Error parsing S21 Phase data. Export aborted.');
      Exit;  end else progressbar.Position:=progressbar.Position+progressbar.Step;  end;
     'S21_deg'://s21 deg
     begin
     if not ParseGpibString(Instrument_Response,S21_DEG) then begin
 ShowMessage('Error parsing S21 Phase data. Export aborted.');
      Exit;    end else progressbar.Position:=progressbar.Position+progressbar.Step; end;
     'S12_deg'://s12 deg
     begin
     if not ParseGpibString(Instrument_Response,S12_DEG) then begin
 ShowMessage('Error parsing S12 Phase data. Export aborted.');
      Exit; end else progressbar.Position:=progressbar.Position+progressbar.Step; end;
    end;
     end;

     for i:=1 to NUM_POINTS do
      begin
      S11_DB[i]:=(-1)*((Abs(S11_DB[i])-Abs(cal_S11_DB[i])));
      S22_DB[i]:=(-1)*((Abs(S22_DB[i])-Abs(cal_S22_DB[i])));
      S21_DB[i]:=(-1)*((Abs(S21_DB[i])-Abs(cal_S21_DB[i])));
      S12_DB[i]:=(-1)*((Abs(S12_DB[i])-Abs(cal_S12_DB[i])));
      S11_deg[i] := S11_deg[i] - cal_S11_deg[i];
      S22_deg[i] := S22_deg[i] - cal_S22_deg[i];
      S21_deg[i] := S21_deg[i] - cal_S21_deg[i];
      S12_deg[i] := S12_deg[i] - cal_S12_deg[i];
      //Check S11
      while S11_deg[i] > 180.0  do S11_deg[i] := S11_deg[i] - 360.0;
    while S11_deg[i] <= -180.0 do S11_deg[i] := S11_deg[i] + 360.0;

    // check S22
    while S22_deg[i] > 180.0  do S22_deg[i] := S22_deg[i] - 360.0;
    while S22_deg[i] <= -180.0 do S22_deg[i] := S22_deg[i] + 360.0;

    // check S21
    while S21_deg[i] > 180.0  do S21_deg[i] := S21_deg[i] - 360.0;
    while S21_deg[i] <= -180.0 do S21_deg[i] := S21_deg[i] + 360.0;

    // check S12
    while S12_deg[i] > 180.0  do S12_deg[i] := S12_deg[i] - 360.0;
    while S12_deg[i] <= -180.0 do S12_deg[i] := S12_deg[i] + 360.0;
      end;

  FreqStep := (StopFreq - StartFreq) / (NUM_POINTS - 1);
 try
    // 1. Make header
     writeToFile(filename,'! Touchstone S2P file generated from HP 3577A VNA via GPIB (Scalar Mode)');
     writeToFile(filename, '! Date/Time: '+ DateTimeToStr(Now));
     writeToFile(filename,'! Frequency Range: '+ FloatToStr(StartFreq)+ ' Hz to '+ FloatToStr(StopFreq)+ ' Hz');
     writeToFile(filename, '! Number of Points: '+ IntToStr(NUM_POINTS));
      // 2. Unit,Type
         writeToFile(filename, '# Hz S DB R 50');
     // 3. For the Standard
         writeToFile(filename, '! Freq(Hz)   S11_db     S11_deg    S21_db     S21_deg    S12_db     S12_deg    S22_db     S22_deg');
     // 4. Write 401 point
    for I := 1 to NUM_POINTS do
    begin
      // calculate the Frequency  Hz
      CurrentFreq := StartFreq + ((I - 1) * FreqStep);
        // Write the headers
      // %-12.0f: Frequency  (Hz) as integer
      // %10.4f: All values dB and degrees as 4 decimal
     writeToFile(FileName, Format('%-12.0f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f', [
        CurrentFreq,
        S11_dB[I], S11_deg[I],
        S21_dB[I], S21_deg[I],
        S12_dB[I], S12_deg[I],
        S22_dB[I], S22_deg[I]
      ]));
    end;
    FileName:='Test_coefficient';
    for I:=1 to NUM_Points do
    begin
    CurrentFreq := StartFreq + ((I - 1) * FreqStep);
    writeToFile(FileName, Format('%-12.0f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f', [
        CurrentFreq,
        S11_dB[I], S11_deg[I],
        S21_dB[I], S21_deg[I],
        S12_dB[I], S12_deg[I],
        S22_dB[I], S22_deg[I],
        cal_S11_dB[I], cal_S11_deg[I],
        cal_S21_dB[I], cal_S21_deg[I],
        cal_S12_dB[I], cal_S12_deg[I],
        cal_S22_dB[I], cal_S22_deg[I]
      ])); end;
  if FileExists( GetUserDir + 'Desktop' + PathDelim +  'S2p.csv') then
  RenameFile( GetUserDir + 'Desktop' + PathDelim + 'S2p.csv', GetUserDir + 'Desktop' + PathDelim + 'Filter.s2p');
  except
    on E:Exception do
    ShowMessage('Error with Writing to the file');
  end;
          end;



procedure TfrmS2P.FormCreate(Sender: TObject);
begin
  txtStopFreq.Text:='';
  txtStartFreq.Text:='';
  cboUnits_StopFreq.ItemIndex:=0;
  cboUntis_StartFreq.ItemIndex:=0;
  HP3577.calibration_proc.IL:=False;
  HP3577.calibration_proc.GD:=False;
  HP3577.calibration_proc.S11:=False;
  HP3577.calibration_proc.S22:=False;
  HP3577.calibration_proc.S12:=False;
  callibration.call_S11:=0;
  callibration.call_S22:=0;
  callibration.call_S21:=0;
  callibration.call_S12:=0;
  callibration.cal_GD:=0;
  progressbar.Position:=0;
  progressbar.Visible:=False;
  staticText1.Visible:=False;
end;

procedure TfrmS2P.txtStartFreqKeyPress(Sender: TObject; var Key: char);
var
  CurrentText: string;
  DecSep: Char;
begin
  // 1. read the text
  CurrentText := TEdit(Sender).Text;
  DecSep := DefaultFormatSettings.DecimalSeparator;

  // 2. adjust  '.' ','
  if (Key = '.') or (Key = ',') then
    Key := DecSep;

  // 3. is on the valid or backspace(#8)
  if not (Key in [#8, '0'..'9',  DecSep]) then
  begin
    Key := #0; //if is not valid remove it and stop
    Exit;
  end;

    // 4. check if only one decimal is exist
  if (Key = DecSep) and (Pos(DecSep, CurrentText) > 0) then
  begin
    Key := #0;
    Exit;
  end;
end;

procedure TfrmS2P.txtStopFreqKeyPress(Sender: TObject; var Key: char);
var
  CurrentText: string;
  DecSep: Char;
begin
  // 1. read the text
  CurrentText := TEdit(Sender).Text;
  DecSep := DefaultFormatSettings.DecimalSeparator;

  // 2. adjust  '.' ','
  if (Key = '.') or (Key = ',') then
    Key := DecSep;

  // 3. is on the valid or backspace(#8)
  if not (Key in [#8, '0'..'9',  DecSep]) then
  begin
    Key := #0; //if is not valid remove it and stop
    Exit;
  end;

    // 4. check if only one decimal is exist
  if (Key = DecSep) and (Pos(DecSep, CurrentText) > 0) then
  begin
    Key := #0;
    Exit;
  end;

end;

    function TfrmS2P.ParseGpibString(const GpibRawStr: string; var TargetArray: TGpibScalarArray): Boolean;
var
  StrList: TStringList;
  I: Integer;
  CleanStr: string;
  FS: TFormatSettings;
begin
  Result := False;

  // ingore the  Locale of  Windows
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';

  StrList := TStringList.Create;
  try
    //  remoce empty chars
    CleanStr := Trim(GpibRawStr);

    // StringList comma separated
    StrList.Delimiter := ',';
    StrList.StrictDelimiter := True;

    // Auto cut string insto pieces comma based
    StrList.DelimitedText := CleanStr;

    // Do we have all 401 data
    if StrList.Count < NUM_POINTS then
    begin
      ShowMessage('Error: Not all numbers have been sent. Missing ' + IntToStr(NUM_POINTS - StrList.Count));
      Exit; // False and exit
    end;

    // make the string into numbers
    try
      for I := 1 to NUM_POINTS do
      begin
        // Trim
        TargetArray[I] := StrToFloat(Trim(StrList[I - 1]), FS);
      end;

      // if not error
      Result := True;

    except

      on E: EConvertError do
      begin
        ShowMessage('Error parsing GPIB string. Invalid characters or format detected.');
        Result := False;
      end;
    end;

  finally
    // release StringList
    StrList.Free;
  end;
end;
    function TfrmS2P.read_response(startFreq,stopFreq:Real;input:String):String;
    var
      Instrument_Response,chunk,command:String;
       FS: TFormatSettings;
    begin
       Instrument_Response:='';
       FS := DefaultFormatSettings;
       FS.DecimalSeparator := '.';
      if prologix.config then
  if prologix.isopen then
  begin
     command:='BD0;FM1;DCH';//initalize as fast as possible
     prologix.Write_Data(command);
     command:='FRA '+FloatToStr(startFreq,FS)+' Hz;FRB '+FloatToStr(stopFreq,FS)+' Hz';
      prologix.Write_Data(command);
     Result:='';
     case input of
     'S11':begin
        command:='I11;DF7';
        prologix.Write_Data(command);

       end;
     'S11_deg':begin
        command:='I11;DF5';
        prologix.Write_Data(command);
       end;
      'S22':
      begin
      command:='I22;DF7;FRA '+FloatToStr(startFreq,FS)+' Hz;FRB '+FloatToStr(stopFreq,FS)+' Hz';
        prologix.Write_Data(command);
         end;
     'S22_deg':
     begin
        command:='I22;DF5';
        prologix.Write_Data(command);
       end;
      'S21':
        begin
        command:='I21;DF7';
        prologix.Write_Data(command);
       end;
     'S21_deg':
       begin
        command:='I21;DF5';
        prologix.Write_Data(command);
      end;
      'S12':
      begin
        command:='I12;DF7';
        prologix.Write_Data(command);
     end;
     'S12_deg':
     begin
        command:='I12;DF5';
        prologix.Write_Data(command);
      end;
   end;
        command:='TKM;DT1';
       prologix.Write_Data(command);

     while (Pos(#13, Instrument_Response) = 0) and (Pos('<0>', Instrument_Response) = 0) do
   begin
    Sleep(2200); // wait for
    Chunk := serials.LazSerial1.ReadData;
    if Chunk <> '' then
      Instrument_Response := Instrument_Response + Chunk;

   end;

  if Pos('<0>', Instrument_Response) > 0 then //remove the <0> if exists
    Instrument_Response := StringReplace(Instrument_Response, '<0>', '', [rfReplaceAll]);
    Result:=Instrument_response;
    end;
     end;


end.

