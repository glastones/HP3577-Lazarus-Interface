unit Test;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids, Spin,
  DataBaseModule,LCLType, Buttons, Menus,hp3577,prologix,windows,misc_function;

type
      { TfrmTest }
  TfrmTest = class(TForm)
    cboSelect: TComboBox;
    chkSave: TCheckBox;
    cbAtten: TCheckBox;
    spSerial: TSpinEdit;
    Qtext: TStaticText;
    stringResult: TStringGrid;
    procedure cbAttenChange(Sender: TObject);
    procedure cboSelectChange(Sender: TObject);
    procedure chkSaveChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);

    procedure stringResultDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure stringResultResize(Sender: TObject);
  private
         cell_col,cell_row:SmallInt;
    procedure ClearData;
    procedure passFail(const machine:Real;measurement_code:SmallInt;const row_idx:Integer);
     procedure FixAndCenterGrid;

  public

  end;


var
 frmTest: TfrmTest;
 // machines:machine_data;
 show_parameters:array of TMeasParam;
 zero_span:Real;
 targetCol,TargetRow:smallInt;
 failed:Boolean;
 oldSerial:SmallInt;
 info:Filter_info;

implementation
 procedure  sound_play;forward;
{$R *.lfm}

{ TfrmTest }

procedure TfrmTest.FormCreate(Sender: TObject);
begin
cell_col:=-1;cell_row:=-1;
   frmTest.top:=(Screen.DesktopHeight-frmTest.Height) div 2;
   frmTest.left:=(screen.DesktopWidth-frmTest.Width)div 2;
   cboSelect.Clear;
   try
   DataModule1.connecting;
  Except
   on E:exception do
   ShowMessage (E.Message);
  end;
   cboSelect.Items.Assign(DataModule1.ReadFilters);
  cboSelect.ItemIndex:=-1;
     clearData;
    spSerial.Visible:=False;
    spSerial.Value:=0;
    chkSave.Checked:=False;
    oldSerial:=0;
    qtext.Visible:=False;
   end;

procedure TfrmTest.FormDestroy(Sender: TObject);
begin
  prologix.close;
end;

procedure TfrmTest.FormKeyPress(Sender: TObject; var Key: char);
var
 i: smallInt;
 //  command_count:smallInt;
 row_idx:smallint;
 code:SmallInt;
 machine_Result,Actual_Center,Actual_span:Real;
 data:string;
begin //key preview enables by the form
//clear the collum 3,4 cells[0,0] headers
for i:=1 to StringResult.RowCount-1 do
  begin
  stringResult.Cells[3,i]:='';
  stringResult.Cells[4,i]:='';
  end;    
 Show_parameters:=nil;
 show_Parameters:=DataModule1.read_vna(trim(cboSelect.Items[cboSelect.ItemIndex]));

  if chkSave.Checked then begin
  if spSerial.Value<=0 then begin
    ShowMessage('Enter A valid Number > 1');
    spSerial.SetFocus;
    Exit;
  end;
  end;
  if oldSerial<>spSerial.Value then//if oldserial<>newserial serial has been changed
  if spSerial.Value<>0 then oldSerial:=spSerial.Value;//get current serial value
  //prepere the data
  for i:=low(Show_parameters) to high(show_parameters) do
  begin
  if show_parameters[i].AUnit='KHz' then show_parameters[i].Value:=show_parameters[i].Value*1000;
  if show_parameters[i].AUnit='MHz' then show_parameters[i].Value:=show_parameters[i].Value*1000000;
  end;
  i:=0;
  //main loop goes here.read paramters send the command receive the results load to the stringresult and
    while i<High(show_parameters) do
  begin
  if show_parameters[i].measurement_code in [0..3,8..9,13,16,19]
  then begin
  hp3577.restore.span:=show_parameters[i+1].Value; //store span
  hp3577.restore.center:=show_parameters[i].Value; //store center frequency
  hp3577.restore.span:=(hp3577.restore.span*0.2)+hp3577.restore.span;//restore span is 20% of span increased
  if show_parameters[i].measurement_code in [8..9,13,16,19,2] then inc(i,3)
  else if show_parameters[i].measurement_code in[0,3] then inc (i,2);
  end;
  inc(i);
  end;
  if  prologix.config then  //config proloxig communicate with the machine.
 // begin
   prologix.connect;
  //removed in final version
  prologix.Write_Data('IPR;BD0;FM1;DCH');//Reset and initialize as fast as possible.
  sleep(sleep_time);
  i:=0;
  row_idx:=1;

  while (i<=High(Show_parameters)) and (key<>#27 )  do
  begin
  Application.ProcessMessages;
  case show_parameters[i].measurement_code of
  0..1: begin
   // for command_count:=1 to 2 do
    machine_result:=IL(show_parameters[i].Value,show_parameters[i+1].Value,show_parameters[i].measurement_code);
    code:=show_parameters[i].measurement_code;
    stringResult.Cells[3,row_idx]:=FloatTostr(machine_result);
    zero_span:=show_parameters[i+1].Value;
    passFail(machine_result,code,row_idx);
    inc(i,2);
    inc(row_idx);
  end;
  2:begin
   //center frequency
    machine_result:=center_frequnency_x_db(show_parameters[i].Value,show_parameters[i+1].Value,show_parameters[i+2].Value);
    stringResult.Cells[3,row_idx]:=FloatTostr(machine_result);
    code:=show_parameters[i].measurement_code;
    passFail(machine_result,code,row_idx);
    inc(i,3);
    inc(row_idx);
  end;
  //Ripple
  3:begin
    machine_result:=Ripple(show_parameters[i].Value,show_parameters[i+1].Value);
    stringResult.Cells[3,row_idx]:=FloatToStr(machine_result);
    code:=show_parameters[i].measurement_code;
    passFail(machine_result,code,row_idx);
    inc(i,2);
    inc(row_idx);
  end;
  4:begin
    //attenuation at stopband must be corrected.
    machine_result:=Attenuation_at_stopband(show_parameters[i].Value,show_parameters[i+1].Value,show_parameters[i+2].Value,show_parameters[i+3].Value,show_parameters[i+4].Value,show_parameters[i].measurement_code);
    stringResult.Cells[3,row_idx]:=FloatToStr(machine_result);
    code:=show_parameters[i].measurement_code;
    passFail(machine_result,code,row_idx);
    inc(row_idx);
    machine_result:=Attenuation_at_stopband(show_parameters[i].Value,show_parameters[i+1].Value,show_parameters[i+2].Value,show_parameters[i+3].Value,show_parameters[i+4].Value,show_parameters[i].measurement_code+1);
    stringResult.Cells[3,row_idx]:=FloatToStr(machine_result);
    code:=show_parameters[i].measurement_code;
    passFail(machine_result,code,row_idx);
    inc(i,5);
    inc(row_idx);
  end;
   5..6: begin
    machine_result:=spurious_ultimate(show_parameters[i].Value,zero_span,show_parameters[i+1].Value);
    stringResult.Cells[3,row_idx]:=FloatToStr(machine_result);
    code:=show_parameters[i].measurement_code;
    passFail(machine_result,code,row_idx);
    inc(i,2);
    inc(row_idx);
  end;
  14..15,17..18,7:begin  //group delay
    machine_result:=GroupDelay(show_parameters[i].Value,show_parameters[i+1].Value,show_parameters[i].measurement_code);
    stringResult.Cells[3,row_idx]:=FloatToStr(machine_result);
    code:=show_parameters[i].measurement_code;
    passFail(machine_result,code,row_idx);
    if ((show_parameters[i].measurement_code=7) or (show_parameters[i].measurement_code=18)) then inc (i,4)
    else if (show_parameters[i].measurement_code=17) then inc(i,3)
    else if ((show_parameters[i].measurement_code=14) or (show_parameters[i].measurement_code=15)) then inc (i,2);
    inc(row_idx);
  end;
    10..11:begin  //s11 S22
    machine_result:=RL(show_parameters[i].Value,show_parameters[i+1].Value,show_parameters[i].measurement_code);
    stringResult.Cells[3,row_idx]:=FloatTostr(machine_result);
    code:=show_parameters[i].measurement_code;
    passFail(machine_result,code,row_idx);
    inc(i,2);
    inc(row_idx);
  end;

  12,16:begin
    machine_result:=attn_at_Freq(show_parameters[i].Value,show_parameters[i+1].Value,show_parameters[i+2].Value,show_parameters[i].measurement_code);
    stringResult.Cells[3,row_idx]:=FloatToStr(machine_result);
    code:=show_parameters[i].measurement_code;
    passFail(machine_result,code,row_idx);
    inc(i,3);
    inc(row_idx);
  end;

  //bandwidth
  8..9,13,19: begin
   machine_result:=bandwidth(show_parameters[i].Value,show_parameters[i+1].Value,show_parameters[i+2].Value,show_parameters[i].measurement_code);
   stringResult.Cells[3,row_idx]:=FloatToStr(machine_result);
   code:=show_parameters[i].measurement_code;
   passFail(machine_result,code,row_idx);
   inc(i,3);
   inc(row_idx);
  end;
  end;
  end;

 if  chksave.Checked then
 begin
 data:=''; //clear the string
 if not failed then
begin
 for i:=0 to stringResult.RowCount-1 do
 begin
 //collect the data and write line by line
 //if empty do not do anything.
 if (Trim(stringResult.cells[1,i])='') and (Trim(stringResult.cells[2,i])='') and (Trim(stringResult.cells[3,i])='') and (Trim(stringResult.cells[4,i])='') then
 continue; //skip everything.
 if i=0 then
 begin
// write headers
 data:='Serial Number'+','+stringResult.cells[0,i]+','+stringResult.Cells[1,i]+','+stringResult.Cells[3,i]+','+stringresult.cells[4,i]+#10;
 WriteToFile(Trim(cboselect.Items[cboselect.ItemIndex]),data);
 continue;
 end;
 if spSerial.Value=oldserial then
  data:=' ,'+','+stringResult.cells[1,i]+','+stringResult.Cells[2,i]+','+stringResult.Cells[3,i]+','+stringresult.cells[4,i]+#10
  else
 data:=IntToStr(spSerial.Value)+','+stringResult.cells[1,i]+','+stringResult.Cells[2,i]+','+stringResult.Cells[3,i]+','+stringresult.cells[4,i]+#10;
     WriteToFile(Trim(cboselect.Items[cboselect.ItemIndex]),data);
   data:='' //clear the string
 end;
 end;
 spSerial.Value:=spSerial.Value+1;   //next serial number
 oldSerial:=spSerial.Value;
 end;
 if not failed then
 if info.filter_type=2 then
 begin
 if not qtext.Visible then qtext.Visible:=true;
 qtext.Caption:='Request Q =  '+FloatToStr(Filter_Q(restore.center,restore.span))+' | Actual  Q = '+FloatToStr(Filter_Q(Actual_Center,Actual_Span));
 end
 else
 qtext.Visible:=False;

 Restore_View(hp3577.restore.center,hp3577.restore.span);
 prologix.release;
 end;

//type-of-measurement=min or max optional,4. spec_value -xdb or anything else need it.
procedure tfrmTest.passFail(const machine:Real;measurement_code:SmallInt;const row_idx:Integer);     //completed dddddddddddddddddddddddddddddddddddddddddddddddddd
var
 i:smallInt;
 show_parameters:array of TMeasParam;
begin
  failed:=False;
  show_parameters:=nil;
  TargetRow:=0;TargetCol:=4;
  show_parameters:=Datamodule1.variable_for_passFail(trim(cboselect.Items[cboselect.ItemIndex]));

  i:=0;
  while (i <= High(show_parameters)) and (show_parameters[i].measurement_code <> measurement_code) do begin
    inc(i);
    if i > High(show_parameters) then Exit; // No limit found for this measurement_code
    end;

  case measurement_code of
  0..1,3,19:begin   //better than   {-3>-5 true}
    if show_parameters[i].value>=machine  then begin
    failed:=True;
    StringResult.Cells[4,row_idx]:='Failed';
    sound_play;
    TargetRow:=row_idx;
    StringResult.Invalidate;
    end
    else StringResult.cells[4,row_idx]:='Pass';
     end;
  8: begin
      if machine>=show_parameters[i].value  then StringResult.Cells[4,row_idx]:='Pass'
      else begin failed:=True; StringResult.cells[4,row_idx]:='Failed';sound_play;TargetRow:=row_idx; StringResult.Invalidate; end;
     end;

//all gd
7,14,15,17,18: begin
    if machine>show_parameters[i].value  then begin failed:=True;StringResult.Cells[4,row_idx]:='Failed';sound_play;TargetRow:=row_idx; StringResult.Invalidate; end
    else StringResult.cells[4,row_idx]:='Pass';
   end;

  4..6,10..11:                       //worst than
  begin
    if show_parameters[i].value<=machine  then begin failed:=True;StringResult.Cells[4,row_idx]:='Failed';sound_play;TargetRow:=row_idx; StringResult.Invalidate; end
    else StringResult.cells[4,row_idx]:='Pass';
     end;
  13:begin
    if Show_Parameters[i+1].AUnit='Min' then
    begin
      if machine>show_parameters[i].Value then  StringResult.Cells[4,row_idx]:='Pass'
      else begin failed:=True;StringResult.Cells[4,row_idx]:='Failed';sound_play;TargetRow:=row_idx; StringResult.Invalidate; end;
        end
    else if Show_Parameters[i+1].AUnit='Max' then
    begin
      if machine<=show_parameters[i].Value then  StringResult.Cells[4,row_idx]:='Pass'
      else begin failed:=True; StringResult.Cells[4,row_idx]:='Failed';sound_play;TargetRow:=row_idx; StringResult.Invalidate; end;
    end;
    end;
  12,16:begin
   if Show_Parameters[i].AUnit='Min' then
    begin
      if machine>show_parameters[i].Value then  StringResult.Cells[4,row_idx]:='Pass'
      else begin failed:=True;StringResult.Cells[4,row_idx]:='Failed';sound_play;TargetRow:=row_idx; StringResult.Invalidate; end;
        end
    else if Show_Parameters[i].AUnit='Max' then
    begin
      if machine<=show_parameters[i].Value then  StringResult.Cells[4,row_idx]:='Pass'
      else begin failed:=True; StringResult.Cells[4,row_idx]:='Failed';sound_play;TargetRow:=row_idx; StringResult.Invalidate; end;
    end;
    end;

  2:begin  // if FC =(fhihg+flow)/2
    if (((show_parameters[i].Value+show_parameters[i+1].Value)/2)=machine) then
      StringResult.Cells[4,row_idx]:='Pass'
    else
   begin failed:=True; StringResult.Cells[4,row_idx]:='Failed';sound_play;TargetRow:=row_idx;  StringResult.Invalidate;end;
    end;
  9:begin
    //bw max                                                             bw min
    if ((machine>show_parameters[i+3].Value-show_parameters[i].Value)  or (machine<show_parameters[i+1].Value-show_parameters[i+2].Value))
    then begin failed:=True; StringResult.Cells[4,row_idx]:='Failed';sound_play;TargetRow:=row_idx; StringResult.Invalidate; end
    else StringResult.Cells[4, row_idx] := 'Pass';
    end;
  end;

  for i := 0 to StringResult.Columns.Count - 1 do
  begin
    StringResult.Columns[i].Alignment := taCenter;
  end;

  end;

procedure TfrmTest.FormShow(Sender: TObject);
begin
   cboSelect.Items.Assign(DataModule1.ReadFilters);
  cboSelect.ItemIndex:=-1;
  StringResult.Clear;
      cbatten.Checked:=True;
   self.top:=(Screen.DesktopHeight-self.Height) div 2;
   self.left:=(screen.DesktopWidth-self.Width)div 2;
end;



procedure TfrmTest.stringResultDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  TextStyle: TTextStyle;
  Grid: TStringGrid;
  CellText: string;
begin
  Grid := Sender as TStringGrid;
  CellText := Grid.Cells[aCol, aRow];

  // headers exclude
  if aRow < Grid.FixedRows then
    Exit;

  // 2.if col 4
  if aCol = 4 then
  begin
    // if fail
    if (CellText = 'Failed') or (CellText = 'Fail') then
    begin
      Grid.Canvas.Brush.Color := clRed;     // Red
      Grid.Canvas.Font.Color := clWhite;    // white letters
    end
    //optional "Passed"
    else if (CellText = 'Passed') or (CellText ='Pass') then
    begin
      Grid.Canvas.Brush.Color := clGreen;   // Green
      Grid.Canvas.Font.Color := clWhite;    // White letter
    end

  end
  else
  begin
    // 3. All other shoould be the default
    Grid.Canvas.Brush.Color := clWhite;
    Grid.Canvas.Font.Color := clBlack;
  end;

  // redraw
  Grid.Canvas.FillRect(aRect);

  // Text in the center
  TextStyle := Grid.Canvas.TextStyle;
  TextStyle.Alignment := taCenter;
  TextStyle.Layout := tlCenter;
  TextStyle.Clipping := True;

  // for all cells text in the center.
  Grid.Canvas.TextRect(aRect, aRect.Left + 2, aRect.Top + 2, CellText, TextStyle);
end;

procedure TfrmTest.stringResultResize(Sender: TObject);
begin
FixAndCenterGrid;
  end;


procedure TfrmTest.chkSaveChange(Sender: TObject);
var
 fil_type:String;
begin
  fil_type:='';
  if trim (cboselect.Items[cboselect.ItemIndex])='' then
  begin
  ShowMessage('Choose filter First');
  chkSave.Checked:=False;
  cboselect.SetFocus;
  Exit;
  end;
  if  chkSave.Checked then
  begin
    spSerial.Visible:=True;
 if  Messagedlg('Enter Serial To Start measurement','Enter Serial',mtInformation,[mbOK, mbCancel],0)=mrCancel then
 begin
   chkSave.Checked:=False;
   spSerial.Value:=0;
   spSerial.Visible:=False;
  end;
  end;
  if not chksave.Checked then
  begin
    spSerial.Visible:=False;
    spSerial.Value:=0;
  end;
  fil_type:='Serial Number'+','+stringResult.Cells[0,0]+','+stringResult.Cells[1,0]+','+stringResult.Cells[2,0]+','+stringResult.Cells[3,0]+','+stringResult.Cells[4,0]+#13;
 writeTofile(trim(cboSelect.Items[cboselect.ItemIndex]),fil_type);
end;


 //Show the data for the User Reads the table Show.
procedure TfrmTest.cboSelectChange(Sender: TObject);
var
   i,j:integer;
   filepath:String;
   begin
  clearData;
  j:=1; i:=0;
  //new filter new calibration
  HP3577.calibration_proc.IL:=False;
  HP3577.calibration_proc.GD:=False;
  HP3577.calibration_proc.S11:=False;
  HP3577.calibration_proc.S22:=False;
  show_Parameters:=nil;
  filepath:=GetUserDir + 'Desktop' + PathDelim + Trim(cboSelect.Items[cboselect.ItemIndex])+'.csv';
  if FileExists(filepath) then
  DeleteFile(pchar(filepath)); //if file already exist erase it
  WriteToFile(Trim(cboselect.Items[cboselect.ItemIndex]),cboselect.Items[cboselect.ItemIndex]+#10);   //write filter name
  show_Parameters:=DataModule1.read_show(trim(cboSelect.Items[cboSelect.ItemIndex]));
   while i<=High(Show_parameters) do
   begin
   StringResult.Rowcount:=j+1;
   StringResult.cells[0,j]:=IntToStr(j-1);
    StringResult.cells[1,j]:=Show_parameters[i].measurement_Type;
   case Show_parameters[i].measurement_code of
   0..1,5..6,14..15,10..11,3:
    begin
    StringResult.cells[2,j]:=floattoStr(Show_parameters[i].Value)+' '+Show_parameters[i].AUnit;
   inc(i);
   inc(j);
     end;
    2,7,18: begin
    StringResult.cells[2,j]:='[ F0 + '+floatToStr(Show_parameters[i].Value)+' '+Show_parameters[i].Aunit+' to F0  ' + floatToStr((-1)*Show_parameters[i+1].Value)+' '+show_parameters[i+1].AUnit +']'+' '+floattoStr(Show_parameters[i+2].Value)+' '+Show_parameters[i+2].AUnit;
   inc(j);
   inc(i,3);
   end;
    4: begin
    StringResult.cells[2,j]:='[ F0  '+floatToStr((-1)*Show_parameters[i].Value)+Show_parameters[i].Aunit+' ] '+' '+floattoStr(Show_parameters[i+2].Value)+' '+Show_parameters[i+2].AUnit;;
         inc(j);
    StringResult.Rowcount:=j+1;
    StringResult.cells[1,j]:=Show_parameters[i].measurement_Type;
     StringResult.cells[2,j]:='[ F0 + ' + floatToStr(Show_parameters[i+1].Value)+show_parameters[i+1].AUnit +' ] '+' '+floattoStr(Show_parameters[i+2].Value)+' '+Show_parameters[i+2].AUnit;
              inc(j);
    StringResult.Rowcount:=j+1;
   inc(i,3);
   end;
   8,12..13,19,16..17:
    begin
       StringResult.cells[2,j]:='[ '+show_parameters[i].Name+' = '+floatToStr(Show_parameters[i].Value)+' '+Show_parameters[i].Aunit+' ] ' + ' '+ floatToStr(Show_parameters[i+1].Value)+' '+Show_parameters[i+1].Aunit;
    inc(j);
   inc(i,2);
    end;
   9:
    begin
     StringResult.cells[2,j]:=' [  From '+FloatToStr(show_parameters[i].Value)+' To '+FloatToStr(show_parameters[i+3].Value)+' ] '+FloatToStr(Show_parameters[i+5].Value)+' '+Show_parameters[i+5].Aunit;
    inc(j);
   inc(i,5);
    end;
      end;
      end;
   //center the string grid on the center of the background white space
   FixAndCenterGrid;
//   after that size the collum
     StringResult.AutoSizeColumns;
      info:=datamodule1.ReadFilterInfo(Trim(cboSelect.Items[cboSelect.ItemIndex]));
      end;

procedure TfrmTest.cbAttenChange(Sender: TObject);
begin
if prologix.isopen then
begin
  if not cbatten.Checked then
  begin
  cbatten.Caption:='Zin=Zout<>50 ohm';
  showMessage('Attenuation -20db will be active on all measurements');
  try
  prologix.Write_Data('AB2');
  Except
   on E:exception do
   begin
   showMessage (e.Message);
  Exit;
  end;
  end
  end
  else
  begin
  cbatten.Caption:='Zin=Zout=50 ohm';
    showMessage('Attenuation -20db will be deactive on all measurements');
    try
    prologix.Write_Data('AB1');
    Except
   on E:exception do
   begin
   showMessage (e.Message);
  Exit;
  end;
    end;
end;
  end;
    end;
 procedure TfrmTest.ClearData;
 begin
  StringResult.Clear;
  stringResult.clean;
  StringResult.ColCount := 5;
  StringResult.RowCount := 4;
  StringResult.Cells[0,0]:=' Measurement ';
  StringResult.Cells[1,0]:=' Measurement Paramter ';
  StringResult.Cells[2,0]:=' Desired Value ';
  StringResult.Cells[3,0]:=' Measured Value ';
    StringResult.Cells[4,0]:=' Result ';
 end;
 procedure sound_play;
 var
   i:Integer;
   begin
 for i:= 1 to 2 do
    begin
      Windows.Beep(800, 150);  // High tone
      Windows.Beep(600, 150);  // Lower tone
      //prologix.Write_Data('Beep');
    end;

   end;
  procedure TfrmTest.FixAndCenterGrid;
var
  i: smallInt;
  TotalGridWidth: smallInt;
  TotalGridHeight: smallInt;
begin
 //collum autosize
  StringResult.AutoSizeColumns;

  // widht of all the collumn
  TotalGridWidth := 0;
  for i := 0 to StringResult.ColCount - 1 do
  begin
    TotalGridWidth := TotalGridWidth + StringResult.ColWidths[i];
  end;

  // Safety add pixels
  TotalGridWidth := TotalGridWidth + (StringResult.GridLineWidth * (StringResult.ColCount - 1)) + 2;

  // apply to the entire grid
  StringResult.Width := TotalGridWidth;

  // Horizontal center
  StringResult.Left := (StringResult.Parent.ClientWidth - StringResult.Width) div 2;

  // Calculate height
  TotalGridHeight := 0;
  for i := 0 to StringResult.RowCount - 1 do
  begin
    TotalGridHeight := TotalGridHeight + StringResult.RowHeights[i];
  end;
  // safety pixes
  TotalGridHeight := TotalGridHeight + (StringResult.GridLineWidth * (StringResult.RowCount - 1)) + 2;

  // New dimensions
  StringResult.Width := TotalGridWidth;
  StringResult.Height := TotalGridHeight;

  // centered on the screen
  StringResult.Left := (StringResult.Parent.ClientWidth - StringResult.Width) div 2;
end;



end.

