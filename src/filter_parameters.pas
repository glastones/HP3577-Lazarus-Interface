unit Filter_parameters;

{$mode ObjFPC}{$H+}{$R+}

interface

uses
  Classes, SysUtils, SQLDB,  SQLite3Conn, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Menus,DataBaseModule,Show_correct;

type
  TFormMode=(fmNew,fmEdit);
  { TfrmParameters }

  TfrmParameters = class(TForm)
    btnNext: TButton;
    btnFinish: TButton;
    cboUnits1: TComboBox;
    cboUnits3: TComboBox;
    cboMeasurement: TComboBox;
    cboUnits2: TComboBox;
    cboUnits4: TComboBox;
    cboUnits5: TComboBox;
    ckbChange: TCheckBox;
    cboCenterFUnits: TComboBox;
    cboSpanUnits: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    lblParameter1: TLabel;
    lblParameter2: TLabel;
    lblParameter3: TLabel;
    lblParameter4: TLabel;
    lblparameter5: TLabel;
    lblParameter6: TLabel;
    lblParameter7: TLabel;
    lblParameter8: TLabel;
    lblParameter9: TLabel;
    lblParameter: TLabel;
    procedure btnFinishClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure cboCenterFUnitsChange(Sender: TObject);
    procedure cboMeasurementChange(Sender: TObject);

    procedure ckbChangeChange(Sender: TObject);

    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    function Fill_data:Boolean;
     procedure insert_data(Edit:Boolean);
      function test(choose:SmallInt):SmallInt;
     procedure Reset_Controls;
     procedure Show_Controls(label_num,Edit_num,Cbo_num:ShortInt);
     procedure EditKeyPress(Sender: TObject; var Key: Char);
     procedure autocomplete;
     procedure SetFormMode(AMode: TFormMode);

    function check_values:Boolean;
    function checked(value:TEdit;texts:TLabel):Boolean;
  private
      FFormMode: TFormMode;

     FLabels: array[1..9] of TLabel;
      EDITAR: array[1..9] of TEdit;
      CBOAR: array[1..7] of TComboBox;
      data_description:Array[1..10] of string;
      data_values:Array[1..10]of Double;
      data_units:Array[1..8] of integer;
      data_punit:Array[1..9] of string;
      show_to_user:Array[1..10]of integer;//information of what user should be seen
      send_to_vna:Array[1..10]of integer;//information which should be used for VNA only
      variable_for_Result:Array[1..10]of integer;  //store desired values for comparison
      // FIX: pinned settings so numeric parsing does not depend on the machine
      // locale (e.g. comma vs dot on Greek Windows).
      FFS: TFormatSettings;
  public
      property FormMode: TFormMode read FFormMode write SetFormMode;
  end;

var
  frmParameters: TfrmParameters;
  parameters,show_indexing,last_time_units:Integer;
  cf,span:String;
implementation
uses information;
{$R *.lfm}

{ TfrmParameters }

procedure TfrmParameters.FormCreate(Sender: TObject);
var
  i:Integer;
begin
   // FIX: pin decimal point so number entry is locale-independent.
   FFS := DefaultFormatSettings;
   FFS.DecimalSeparator := '.';
   FFS.ThousandSeparator := #0;
   FLabels[1] := lblparameter1;
   FLabels[2] := lblparameter2;
   FLabels[3] := lblparameter3;
   FLabels[4] := lblparameter4;
   FLabels[5] := lblparameter5;
   FLabels[6] := lblparameter6;
   FLabels[7] := lblparameter7;
   FLabels[8] := lblparameter8;
   FLabels[9] := lblparameter9;


   EDITAR[1]:=Edit1;
   EDITAR[2]:=Edit2;
   EDITAR[3]:=Edit3;
   EDITAR[4]:=Edit4;
   EDITAR[5]:=Edit5;
   EDITAR[6]:=Edit6;
   EDITAR[7]:=Edit7;
   EDITAR[8]:=Edit8;
   EDITAR[9]:=Edit9;


   CBOAR[1]:=cboCenterFUnits;
   CBOAR[2]:=cboSpanUnits;
   CBOAR[3]:=cboUnits1;
   CBOAR[4]:=cboUnits2;
   CBOAR[5]:=cboUnits3;
   CBOAR[6]:=cboUnits4;
   CBOAR[7]:=cboUnits5;

  for i:=1 to High(Editar) do
  EDitar[i].OnKeyPress:=@EditKeyPress;

  ckbchange.Visible:=False;



reset_controls;


 lblParameter.Visible:=True;
 lblParameter.Caption:='Choose Parameter ';
 lblParameter1.Caption:='Center Frequency ';
 lblParameter2.Caption:='Span ';
 lblParameter3.Caption:='Scale in db ';
 lblParameter4.Caption:='Reference Position in db ';


 frmParameters.top:=(Screen.DesktopHeight-frmParameters.Height) div 2;
 frmParameters.left:=(screen.DesktopWidth-frmParameters.Width)div 2;
 cbomeasurement.Visible:=True;

 //flag to zero
  for i := 1 to High(data_description)do data_description[i]:='';
 for i := Low(show_to_user) to High(show_to_user)do show_to_user[i]:=0;
 for i := Low(send_to_vna) to High(send_to_vna)do send_to_vna[i]:=0;
 for i := Low(variable_for_Result) to High(variable_for_Result)do variable_for_Result[i]:=0;
 cf:='';Span:='';
 show_indexing:=0;
 last_time_units:=0;
end;

procedure TfrmParameters.cboMeasurementChange(Sender: TObject);
var
  i:integer;
begin
   Reset_controls;

           for i := 1 to High(data_description)do data_description[i]:='';
          for i := 1 to High(data_values)do  data_values[i]:=0;
          for i := 1 to High(data_units)do  data_units[i]:=0;
   CBOAR[3].Items.Clear;
   CBOAR[3].Items.Add('Hz');
   CBOAR[3].Items.Add('KHz');
   CBOAR[3].Items.Add('MHz');
    CBOAR[3].ItemIndex:=0;

{     to be checked
0 Insertion Loss                   ok
1 Insertion Loss at center Frequency ok
2 Center Frequency at -xdB         ok
3 Ripple at bandpass               ok
4 Attenuation at stopband          ok
5 Spurious attenuation             ok
6 Ultimate attenuation             ok
7 Group Delay in a BW (ref @ min)  ok
8 Bandwidth at -xdB                ok
9 Passband Window at -xdB          ok
10 S11 (max) (return loss          ok
11 S22 (max) (return loss)         ok
12 Atten. at freq. (min/max)       ok
13 Total bandwidth xdB (min/max)   ok
14 Group delay variation           ok
15 Max group delay                 ok
16 Atten. at freq.+I.L. (min/max)  ok
17 Group Delay in a BW (ref @ cf)  ok
18 Absolute Group Delay @ Freq.    ok
19 Bandwidth at -xdB (ref @ cf)    ok}

for i:=low(send_to_vna) to 2 do send_to_vna[i]:=1; //set flag to send to vna
ckbchange.Visible:=True;
lblParameter1.Caption:='Center Frequency ';
lblParameter2.Caption:='Span ';
lblParameter3.Caption:='Scale in db ';
lblParameter4.Caption:='Reference Position in db ';

    case cbomeasurement.ItemIndex  of
 0..1:begin  //show parameters for insertion loss
   show_to_user[5]:=1;
   variable_for_Result[5]:=1;
 lblParameter5.Caption:='Requirement Value -x db';
  Show_controls(5,5,2);
      autocomplete;
 end;
 2:begin
//   show parameters for center frequency @-x db bandwidth
 Show_Controls(7,7,4);
 for i:=5 to 7 do begin show_to_user[i]:=1; variable_for_Result[i]:=1; end;
   send_to_vna[7]:=1;
  variable_for_Result[7]:=1;//depend  how to implement
     lblParameter5.Caption:='Low Limit';
     lblParameter6.Caption:='High Limit';
     lblParameter7.Caption:='-x db';


     autocomplete;
   end;
 3:begin //show parameters for Ripple
       Show_Controls(5,5,2);
           show_to_user[5]:=1;
           //send_to_vna[5]:=1;
           variable_for_Result[5]:=1;
       lblParameter5.Caption:='Ripple in db';
              autocomplete;
 end;
 4:begin //attenuation at stopband
     Show_Controls(7,7,4);
     for i:=5 to 7 do begin show_to_user[i]:=1;send_to_vna[i]:=1; end;
     variable_for_Result[7]:=1;
     lblParameter5.Caption:='Low Frequency';
     lblParameter6.Caption:='High Frequency';
     lblParameter7.Caption:='Attenuation -x db';




           autocomplete;
 end;
 5:begin // show parameters for Spurious attenuation
      Show_controls(5,5,2);
       show_to_user[5]:=1; variable_for_Result[5]:=1;
      lblParameter5.Caption:='Spures in db';
                autocomplete;
 end;
 6:begin
   //show parameters for ultimate
      Show_controls(5,5,2);
      show_to_user[5]:=1;  variable_for_Result[5]:=1;
      lblParameter5.Caption:='Ultimate in db';
                         autocomplete;
 end;
  7://show group delay from min
    begin
     Show_Controls(7,7,4);
      for i:=5 to 7 do begin show_to_user[i]:=1; end;
      variable_for_Result[7]:=1; send_to_vna[5]:=1; send_to_vna[6]:=1;
    lblParameter7.Caption:='value in us';
    lblParameter6.Caption:='Upper Frequency ';
    lblParameter5.Caption:='Lower Frequency';
         autocomplete;
     end;
   8:
      begin
   //show parameters for passband -x db
       Show_Controls(6,6,3);
        for i:=5 to 6 do show_to_user[i]:=1;
        variable_for_Result[5]:=1; send_to_vna[6]:=1;
       lblParameter5.Caption:='Total bandwidth';
       lblParameter6.Caption:='-x in db';
             autocomplete;
   end;
     9:
       begin //show parameters for passband -x db window
   Show_Controls(9,9,6);
    for i:=5 to 9 do show_to_user[i]:=1;
    for i:=5 to 8 do variable_for_Result[i]:=1; send_to_vna[9]:=1;
  lblParameter5.Caption:='Low Side Lower Frequency';
  lblParameter6.Caption:='Low Side High Frequency';
  lblParameter7.Caption:='High Side Low Frequency';
  lblParameter8.Caption:='High Side High Frequency';
  lblParameter9.Caption:='-x db';
       autocomplete;
  end;
  10..11:begin
  //show parameters for S11 S22
     Show_controls(5,5,2);
      show_to_user[5]:=1; variable_for_Result[5]:=1;
     lblParameter5.Caption:=' Value in -x db  ';



          autocomplete;
 end;

 12:begin
  // Atten. at freq. (min/max)
   Show_controls(7,7,4);
   CBOAR[4].Items.Clear;
   CBOAR[4].Items.Add('Min');
   CBOAR[4].Items.Add('Max');
   CBOAR[4].ItemIndex:=0;
   show_to_user[5]:=1;show_to_user[7]:=1;
   send_to_vna[5]:=1;variable_for_Result[7]:=1;variable_for_Result[6]:=1;
   lblParameter5.Caption:='At frequency';
   lblParameter6.Caption:='Type';
   lblParameter7.Caption:='Atenuation in -x db';
    EDITAR[6].Visible:=False;
           autocomplete;
 end;
 13:begin //Total bandwidth xdB (min/max)
   Show_Controls(7,7,4);
   CBOAR[4].Items.Clear;
   CBOAR[4].Items.Add('Min');
   CBOAR[4].Items.Add('Max');
   CBOAR[4].ItemIndex:=0;
    show_to_user[5]:=1;    show_to_user[7]:=1; send_to_vna[7]:=1;
            variable_for_Result[6]:=1;
    variable_for_Result[5]:=1;
   lblParameter5.Caption:='Total Bandwidth';
   lblParameter7.Caption:='-x db';
   lblParameter6.Caption:='Type';
   EDITAR[6].Visible:=False;
        autocomplete;
 end;
 14..15://Group delay 14-15 from original
   begin
    Show_Controls(5,5,2);
     show_to_user[5]:=1;
     variable_for_Result[5]:=1;
    lblParameter5.Caption:='Value in us';
            autocomplete;
    end;

 16:  //Atten. at freq.+I.L. (min/max)  add sweep time
     begin;
       Show_controls(7,7,4);
       CBOAR[4].Items.Clear;
       CBOAR[4].Items.Add('Min');
       CBOAR[4].Items.Add('Max');
       CBOAR[4].ItemIndex:=0;
        show_to_user[5]:=1; show_to_user[7]:=1;
        send_to_vna[5]:=1;
        variable_for_Result[7]:=1; variable_for_Result[6]:=1;
       lblParameter5.Caption:='At frequency';
       lblParameter6.Caption:='Type';
       lblParameter7.Caption:='Atenuation -x db';
       EDITAR[6].Visible:=False;
       autocomplete;
 end;

 17: //Group Delay in a BW (ref @ cf) add sweep time
     begin

    Show_Controls(6,6,3);
     for i:=5 to 6 do show_to_user[i]:=1;
     send_to_vna[5]:=1;
     variable_for_Result[6]:=1;
    lblParameter6.Caption:='Value in us';
    lblParameter5.Caption:='Bandwidth';
      autocomplete;
    end;
18:  //Absolute Group Delay @ Freq.
    begin
    Show_Controls(8,8,5);
     for i:=6 to 7 do begin show_to_user[i]:=1;send_to_vna[i]:=1;end;
     show_to_user[8]:=1;          variable_for_Result[8]:=1;
    lblParameter8.Caption:='Value in us';
    lblParameter6.Caption:='Low Frequency';
    lblParameter7.Caption:='High Freqnuency';
    lblParameter5.Caption:='Bandwidth';
    //lblParameter9.Caption:='Sweep Time in Sec';
          autocomplete;
    end;

 19:begin  //Bandwidth at -xdB (ref @ cf)
     Show_Controls(6,6,3);
      for i:=5 to 6 do show_to_user[i]:=1;
      send_to_vna[5]:=1;           variable_for_Result[5]:=1;
    lblParameter6.Caption:='-x db for BW';
    lblParameter5.Caption:='Total BW';
           autocomplete;
 end;
end;

end;




procedure TfrmParameters.btnNextClick(Sender: TObject);
var
  i:Integer;
  FS:TFormatSettings;
  param:Double;
begin
 FS:=DefaultFormatSettings;
 FS.DecimalSeparator:='.';
        last_time_units:=cboar[1].ItemIndex;
  if (Editar[1].Text<>'') and (Editar[2].text<>'') then begin cf:=Editar[1].Text; Span:=Editar[2].text; end;
 // FIX: guard against no measurement selected. ItemIndex is reset to -1 after
 // every save, so pressing Next again without re-selecting would otherwise hit
 // cboMeasurement.Items[-1] (ERangeError with {$R+}) in insert_data.

 if cboMeasurement.ItemIndex < 0 then
 begin
   ShowMessage('Select a measurement type first.');
   Exit;
 end;
 param:=0;
 for i:=1 to high(Editar) do
 begin
     if Editar[i].Visible then
     if not (String.IsNullOrEmpty(Editar[i].Text))or ( not (String.IsNullOrWhiteSpace(Editar[i].Text))) then
     if not TryStrToFloat(Editar[i].Text,param,FS) then
     begin
     ShowMessage('Only Numbers Allowed');
     Editar[i].text:='';
     Editar[i].SetFocus;
     exit;
     end;
     if  String.IsNullOrEmpty(Editar[i].Text)or  String.IsNullOrWhiteSpace(Editar[i].Text) then
     if Editar[i].Visible then
     begin
     ShowMessage('Empty fields not allowed');
      Editar[i].SetFocus;
     exit;
     end;
 end;
 if not check_values then Exit;
 for i:=1 to high(FLabels) do begin
     if Editar[i].Visible then
    if (pos('Ripple',Trim(FLabels[i].Caption))>0) or  (pos('-x',Trim(FLabels[i].Caption))>0)or (pos('Ultimate',Trim(FLabels[i].Caption))>0) or (pos('Spures',Trim(FLabels[i].Caption))>0)  then
    begin
    try
    param:=StrToFloat(Trim(Editar[i].Text),FS);
    if param>=0 then begin
    ShowMessage('Only Negative Numbers Allowed.');
    Editar[i].Text:='';
    Editar[i].Focused;
    Exit;
     end;
    Except
   on E: EconvertError do
    begin
       ShowMessage('Error in Convertion '+E.Message);
          Editar[i].Text:='';
          Editar[i].Focused;
          Exit;
    end;
    end;
    end;
     if (pos('Scale',Trim(FLabels[i].Caption))>0)  then
     begin
     try
     param:=StrToFloat(Trim(Editar[i].Text),FS);
     if (param<=0) or (param>10) then
     begin
      ShowMessage('Out of limits. Scale could not be 0 or >10');
      Editar[i].Text:='';
      Editar[i].Focused;
      Exit;
     end;
     except
       on E: EConvertError do
       begin
          ShowMessage('Error in Convertion '+E.Message);
          Editar[i].Text:='';
          Editar[i].Focused;
          Exit;
     end;
   end;
   end;
      end;

  if btnNext.Caption='Update' then
  begin

  if fill_data then insert_data(True);

  ModalResult:=mrOk;
  end
  else
    begin
        if fill_data then insert_data(False);

 cboMeasurement.ItemIndex:=-1;
 //Reset The values of the controls.
 Reset_controls;
   end;
end;

procedure TfrmParameters.cboCenterFUnitsChange(Sender: TObject);
begin
  cboar[2].ItemIndex:=cboar[1].ItemIndex;
end;

procedure TfrmParameters.btnFinishClick(Sender: TObject);
begin
    ModalResult := mrNone;
  if (cboMeasurement.ItemIndex <> -1) and (Trim(Edit1.Text) <> '') then
  begin
  //call the next button to save the
    btnNext.Click;
   if (ModalResult = mrNone) and (cboMeasurement.ItemIndex <> -1) then Exit;
  end;

  try
    datamodule1.connecting;
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;
  ModalResult := mrOk;
end;



procedure TfrmParameters.ckbChangeChange(Sender: TObject);
begin
  if ckbChange.Checked then
  begin
    lblParameter1.Caption:='Start Frequency';
 lblParameter2.Caption:='Stop Frequency';
  end
  else
    begin
   lblParameter1.Caption:='Center Frequency';
 lblParameter2.Caption:='Span';
end;
    cboar[2].ItemIndex:=cboar[1].ItemIndex;
end;

procedure TfrmParameters.FormActivate(Sender: TObject);
begin
   cboMeasurement.ItemIndex:=-1;
end;

                function TfrmParameters.fill_data:Boolean;
                   var
                     i,index:Integer;
                begin
               //clean the arrays
                      Result:=False;index:=0;
               for i := Low(data_description) to High(data_description)do data_description[i]:='';
               for i := Low(data_values) to High(data_values)do  data_values[i]:=0;
               for i := Low(data_units) to High(data_units)do  data_units[i]:=0;
               for i := Low(data_punit) to High(data_punit)do  data_punit[i]:='';

                //save measurement code

                 //store the data
                 index := 1;
                 for i := 1 to test(1) do
                 begin
                  data_description[i] := FLabels[i].Caption;
                  data_values[i] := StrToFloatDef(Trim(Editar[i].Text), 0, FFS);

                  if (Pos(' us', LowerCase(FLabels[i].Caption)) > 0) or
                     (Pos('delay', LowerCase(FLabels[i].Caption)) > 0) then
                    data_punit[i] := 'us'
                  else if Pos('db', LowerCase(FLabels[i].Caption)) > 0 then
                    data_punit[i] := 'db'
                  else if Pos('sec', LowerCase(FLabels[i].Caption)) > 0 then
                    data_punit[i] := 's'
                  else if (index <= 8) and CBOAR[index].Visible then
                  begin
                    data_punit[i] := CBOAR[index].Items[CBOAR[index].ItemIndex];
                    data_units[index] := CBOAR[index].ItemIndex;
                    Inc(index);
                  end;
                 end;

                 if ckbchange.Checked then
                 begin
                  data_description[1] := 'Center Frequency ';
                  data_description[2] := 'Span ';
                 end;


             //check for scale not >10 or <=0 invalid
            if (data_values[3]>10) or (data_values[3]<=0) then
            begin
            ShowMessage('Imposible value 1-10 is valid only');
            Edit3.Text:='';
            Edit3.SetFocus;
             Result:=False;
            exit;
            end;

         // Reset_controls;
          Result:=True;
                     end;

                   procedure TfrmParameters.insert_data(edit:boolean);
                   var
                     i, n: integer;
                     UnitStr: String;
                     P: TMeasParams;
                   begin
                       P:=nil;
                     // FIX: write to the NORMALIZED schema via the repository.
                     // Build a dynamic array of the populated parameters (any
                     // count) and let SaveMeasurement store one row per parameter.
                      SetLength(P, 15);   // upper bound, trimmed below
                     n := 0;
                     for i :=  Low(data_description)  to High(data_description) do
                       if data_description[i] <> '' then
                       begin
                         if data_punit[i] <> '' then
                           UnitStr := data_punit[i]
                         else
                           UnitStr := 'dB'; // default for dB-scale parameters
                         P[n].Name  := data_description[i];
                         P[n].Value := data_values[i];
                         P[n].AUnit := UnitStr;
                         P[n].show_to_user:= show_to_user[i];
                         P[n].send_to_vna:=send_to_vna[i];
                         P[n].measurement_code:=cbomeasurement.ItemIndex;
                         P[n].measurement_Type:=Trim(cboMeasurement.Items[cboMeasurement.ItemIndex]);
                         P[n].Result_code:=variable_for_Result[i];
                         Inc(n);
                           end;
                       SetLength(P, n);    // exact number of parameters

                     try
                       // SaveMeasurement opens the connection, deletes any prior
                       // rows of this (filter, measurement_type) and re-inserts,
                       // then commits/rolls back internally.
                     case edit of
                     False: begin
                         DataModule1.SaveMeasurement(
                         frmInformation.mskFilterName.Text,
                         {Trim(cboMeasurement.Items[cboMeasurement.ItemIndex]),}
                         P);
                         end;
                     True: begin
                      if btnNext.Caption<>'Update' then
                      DataModule1.SaveMeasurement(
                         Trim(Show_correct.frmShow_correct.cboName.Items[Show_correct.frmShow_correct.cboName.ItemIndex]),
                         {Trim(cboMeasurement.Items[cboMeasurement.ItemIndex]),}
                         P);
                     end
                     else
                     DataModule1.ReplaceMeasurement(
                         Trim(Show_correct.frmShow_correct.cboName.Items[Show_correct.frmShow_correct.cboName.ItemIndex]),
                         {Trim(cboMeasurement.Items[cboMeasurement.ItemIndex]),}
                         P);

                   end;
                      except
                       on E: Exception do
                         ShowMessage('Database Error: ' + E.Message);
                     end;
                     end;



                   //Retrurn the count of label=1 , Edits , units
                   function TfrmParameters.test(choose:SmallInt):SmallInt;
var
units:array[1..8]of TCombobox;
paramter_description:Array[1..9]of TLabel;
parameter_value:Array[1..9] of TEdit;
i,parameter_count,parameter_values,unit_count:Shortint;
begin
//find which used
i:=0; Result:=0;
//how many parameters are active
parameter_count:=0;
//how many values are need it
parameter_values:=0;
//how many units are need it
unit_count:=0;
for i:=0 to self.ControlCount-1 do
begin
if (self.controls[i] is TLabel) and (parameter_count<high(paramter_description)) and (self.controls[i] as TLabel).Visible then
begin
  //Do not count the first label which is static.
  if (pos('Choose',trim(self.controls[i].Caption))>0) or (pos('Activate',trim(self.controls[i].Caption))>0) then continue;
  inc(parameter_count);
end;
if (self.controls[i]  is TEdit) and (parameter_values<high(parameter_value)) and ((frmParameters.controls[i] as TEDIT).Visible) then
begin
  inc (parameter_values);
end;
if (self.controls[i] is TCombobox) and (unit_count<High(units))and (self.controls[i] as TCombobox).Visible then
begin
  // do not count as unit the first combobox which has measurement
  if length(Trim((self.controls[i] as TCombobox).Text))>4 then continue; //do not count the selection combobox
  inc(unit_count);
end;
end;
if (choose>3) or (Choose<=0) then ShowMessage('Error in the paramters of Test function');
case choose of
1: Result:=Parameter_count;
2:Result:=Parameter_values;
3:Result:=unit_count;
end;
end;
 procedure TfrmParameters.Reset_Controls;
 var
 i:shortInt;
 begin

   for i:=1 to high(FLabels) do
   FLabels[i].Visible:=False;
   for i:=1 to High(EDITAR)do
   begin
   Editar[i].Visible:=False;
   Editar[i].Text:='';
   end;
   for i:=1 to high(CBOAR) do
   begin
   CBOAR[i].Visible:=False;
   CBOAR[i].ItemIndex:=0;
    end;


   CBOAR[4].Items.Clear;
   CBOAR[4].Items.Add('Hz');
   CBOAR[4].Items.Add('KHz');
   CBOAR[4].Items.Add('MHz');
   CBOAR[4].ItemIndex:=0;
   ckbChange.Checked:=False;
   for i:=Low(Show_To_user) to High(Show_to_user) do show_to_user[i]:=0;
   for i := 1 to High(data_description)do data_description[i]:='';
   for i := Low(send_to_vna) to High(send_to_vna)do send_to_vna[i]:=0;
   for i := Low(variable_for_Result) to High(variable_for_Result)do variable_for_Result[i]:=0;
 end;
    procedure TfrmParameters.Show_Controls(label_num,Edit_num,Cbo_num:ShortInt);
    var
    i:ShortInt;
    begin
    for i:=1 to label_num do
    FLabels[i].Visible:=True;
    for  i:=1 to Edit_num do
    EDitar[i].Visible:=True;
    for i:=1 to Cbo_num do
    CBOAR[i].Visible:=True;
    end;
 procedure TfrmParameters.EditKeyPress(Sender: TObject; var Key: Char);
var
  E: TEdit;
  NewText: String;
  value:Real;
begin
value:=0;
  E := TEdit(Sender);

  if Key = #8 then Exit; // Backspace

  if not (Key in ['0'..'9', '-', '.']) then
  begin
    Key := #0;
    Exit;
  end;

  NewText := Copy(E.Text, 1, E.SelStart) + Key + Copy(E.Text, E.SelStart + E.SelLength + 1, MaxInt);

  // Check the text
  if not (NewText = '-') and
     not (NewText = '.') and
     not (NewText = '-.') and
     not TryStrToFloat(NewText,value, FFS) then
    Key := #0;
end;
 


procedure TfrmParameters.autocomplete;
 var
   i:Integer;
 begin
 cboar[1].ItemIndex:=last_time_units;
 for i:=Low(cboar) to high(cboAr) do
 if cboar[i].Visible then  cboar[i].ItemIndex:=cboar[1].ItemIndex;
 for i:=1 to High(FLabels) do begin
 if FLabels[i].Visible then begin
 if (cf<>'') and (span<>'') then begin Editar[1].Text:=cf; Editar[2].Text:=span; end;
 if pos('Sweep',Trim(FLabels[i].Caption))>0 then EDITAR[i].Text:='1';
 if pos('Reference',Trim(FLabels[i].Caption))>0 then EDITAR[i].Text:='0';
 if (pos('Scale',Trim(FLabels[i].Caption))>0) and (cboMeasurement.ItemIndex in [10..11]) then EDITAR[i].text:='5'; //Return Loss
 if (pos('Scale',Trim(FLabels[i].Caption))>0) and (cboMeasurement.ItemIndex in [4..6,12]) then EDITAR[i].text:='10';//atten,ultimate,spures
 if (pos('Scale',Trim(FLabels[i].Caption))>0) and (cboMeasurement.ItemIndex in [0..3,8..9,19]) then EDITAR[i].text:='1'; //passband
 if cboMeasurement.ItemIndex=13 then EDITAR[7].text:='-3';
 if cboMeasurement.ItemIndex=2 then EDITAR[8].text:='-3';
 if cboMeasurement.ItemIndex=9 then EDITAR[9].text:='-3';
end;
 end;
 end;
 procedure TfrmParameters.SetFormMode(AMode: TFormMode);
begin
  FFormMode := AMode;
   reset_controls;
  case FFormMode of
    fmNew: begin
      Caption := 'Parameters Setup';
       Reset_Controls;
       end;
      fmEdit: begin
      Caption := 'Edit Record';
      btnFinish.Visible:=False;
      btnNext.Caption:='Update';
      end;
    end;
  end;

      function TfrmParameters.check_values:Boolean;
      var
        i:Integer;
        begin
        Result:=False;
        for i:=1 to 3 do
        if not checked(Editar[i],Flabels[i]) then
        begin
        Result:=False;
        Exit;
        end
        else Result:=True;
        case cbomeasurement.ItemIndex of
      19:begin
      for i:=5 to 5 do
      if not checked(Editar[i],Flabels[i]) then
      begin
      Result:=False;
      Exit;
      end
      else
      Result:=True;
      end;

      2,4,7,17:begin
      for i:=5 to 6 do
      if not checked(Editar[i],Flabels[i]) then
      begin
      Result:=False;
      Exit;
      end
      else
      Result:=True;
      end;

0..1,3,5..6,10..16: Result:=True;

      18: begin
       for i:=6 to 7 do
      if not checked(Editar[i],Flabels[i]) then
      begin
      Result:=False;
      Exit;
      end
      else
      Result:=True;
      end;

      9: begin
       for i:=5 to 7 do
      if not checked(Editar[i],Flabels[i]) then
      begin
      Result:=False;
      Exit;
      end
      else
      Result:=True;
      end;


        end;

        end;

    function TfrmParameters.checked(value:TEdit;texts:TLabel):Boolean;
    begin
    Result:=False;
    if value.Text<>'' then
    begin
    if StrToFloat(value.text, FFS)<=0 then
    begin
    ShowMessage('Negative or zero values not allowed on the Field '+texts.Caption+' !!!! Please Try Again. ');
    Result:=False;
    Value.text:='';
    value.SetFocus;
    Exit;
    end
    else
    Result:=True;
    end;
    end;





end.
{     to be checked
0 Insertion Loss                   ok
1 Insertion Loss at center Frequency ok
2 Center Frequency at -xdB         ok
3 Ripple at bandpass               ok
4 Attenuation at stopband          ok
5 Spurious attenuation             ok
6 Ultimate attenuation             ok
7 Group Delay in a BW (ref @ min)  ok
8 Bandwidth at -xdB                ok
9 Passband Window at -xdB          ok
10 S11 (max) (return loss          ok
11 S22 (max) (return loss)         ok
12 Atten. at freq. (min/max)       ok
13 Total bandwidth xdB (min/max)   ok
14 Group delay variation           ok
15 Max group delay                 ok
16 Atten. at freq.+I.L. (min/max)  ok
17 Group Delay in a BW (ref @ cf)  ok
18 Absolute Group Delay @ Freq.    ok
19 Bandwidth at -xdB (ref @ cf)    ok}
      //to be completed.
