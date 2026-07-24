unit Information;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MaskEdit,DataBaseModule;

type

  { TfrmInformation }

  TfrmInformation = class(TForm)
    btnOK: TButton;
    cboFilterType: TComboBox;
    mskFilterName: TMaskEdit;
    txtCustomer: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    mnDescription: TMemo;
    procedure btnOKClick(Sender: TObject);
    procedure cboFilterTypeChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mskFilterNameChange(Sender: TObject);
    procedure mskFilterNameKeyPress(Sender: TObject; var Key: char);

    procedure txtCustomerExit(Sender: TObject);


  private
complete: boolean;
  public

  end;

var
  frmInformation: TfrmInformation;

implementation

{$R *.lfm}

{ TfrmInformation }

procedure TfrmInformation.FormCreate(Sender: TObject);
begin
   complete:=False;
   txtCustomer.Clear;
  mnDescription.Clear;
  cboFilterType.ItemIndex:=0;
   mskFilterName.Text:='';
  cboFilterType.Enabled:=False;
  mnDescription.Enabled:=False;
  txtcustomer.Enabled:=False;
  frmInformation.top:=(Screen.DesktopHeight-frmInformation.Height) div 2;
  frmInformation.left:=(screen.DesktopWidth-frmInformation.Width)div 2;

end;

procedure TfrmInformation.mskFilterNameChange(Sender: TObject);
begin

mnDescription.clear;
if Length(mskFilterName.Text) > 0 then
    begin
case  mskFilterName.Text[1] of
  'M':mnDescription.lines.Add('Those are specifications for Crystal Matching'+slineBreak);
  'F':mnDescription.lines.Add('Those are specifications for Filter Testing'+slineBreak);
  'T':mnDescription.lines.Add('Those are specifications for Intemediate Testing'+slineBreak);
  'R':mnDescription.lines.Add('Those are specifications for Revision of existing filter'+slineBreak);
   end;
    end;

 if  (Length(mskFilterName.Text) = 6) and(mskFilterName.Text[1] in ['A'..'Z']) and(mskFilterName.Text[2] = '-') and(mskFilterName.Text[3] in ['0'..'9']) and(mskFilterName.Text[4] in ['0'..'9']) and (mskFilterName.Text[5] in ['0'..'9']) and (mskFilterName.Text[6] in ['0'..'9']) then
begin
 //has been completed
 complete:=True;
 txtcustomer.Enabled:=True;
 cboFilterType.Enabled:=True;
end;
end;





procedure TfrmInformation.mskFilterNameKeyPress(Sender: TObject; var Key: char);
begin
 //Lock the first letter
  //M for matching
  //F for Filter or Final
  //T for Test
  //R for Revision
    if key=#8 then exit;
   case mskFilterNAme.SelStart of
   0: if not (Key in ['M','F','T','R','m','f','t','r'] )then
  key:=#0;

  2..5: begin
    if not (Key in ['0'..'9']) then
      Key := #0; //Only numbers here
  end

  // anything else #0
  else
    Key := #0;
end;
   end;

procedure TfrmInformation.txtCustomerExit(Sender: TObject);
begin
 if complete then
   begin
mnDescription.lines.Add('Filter Type is ' +Trim(cboFilterType.Items[cboFilterType.ItemIndex])+sLineBreak);
mnDescription.lines.Add('and the customer is '+String.UpperCase((txtCustomer.Text)));
mnDescription.Enabled:=True;
end;
end;

 procedure TfrmInformation.btnOKClick(Sender: TObject);
var
  s:String;
    CurrentTime: TDateTime;
begin
CurrentTime:=now;
  ModalResult := mrNone;
  s:= RightStr(mskFilterName.Text,4);
  if (String.IsNullOrWhiteSpace(s)) or (trim(mskFilterName.Text)='-') then
  begin
    ShowMessage('Correct the Filter Name!');
    frminformation.mskFilterName.SetFocus;
    Exit;
  end;
  // FIX: connecting() raises if the database is missing/unreachable. Handle it
  // here so the user gets a clear message instead of an unhandled exception.
  try
    datamodule1.connecting;
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;

DataModule1.SQLQuery1.Close;
DataModule1.SQLQuery1.SQL.Text := 'SELECT id FROM filters WHERE filter_name = :name';
DataModule1.SQLQuery1.ParamByName('name').AsString := frmInformation.mskFilterName.Text;
DataModule1.SQLQuery1.Open;

if not DataModule1.SQLQuery1.EOF then
begin
  // if exists we inform and exiting
ShowMessage('Filter Name "' + frmInformation.mskFilterName.Text + '" Exists!');
//close query for safety
DataModule1.SQLQuery1.Close;
//if active connection discard all transactions.
  if DataModule1.SQLTransaction1.Active then
   DataModule1.SQLTransaction1.Rollback;
  Exit;
end;
DataModule1.SQLQuery1.Close;
  try
  // Insert Filter Information (from frmInformation)
        DataModule1.SQLQuery1.SQL.Text := 'INSERT INTO filters (filter_name, customer, filter_type, description, date_created) ' +
                         'VALUES (:name, :customer, :type, :desc, :date)';
        DataModule1.SQLQuery1.Params.ParamByName('name').AsString := frmInformation.mskFilterName.Text;
        DataModule1.SQLQuery1.Params.ParamByName('customer').AsString := frmInformation.txtCustomer.Text;
        DataModule1.SQLQuery1.Params.ParamByName('type').AsInteger := frmInformation.cboFilterType.ItemIndex;
        DataModule1.SQLQuery1.Params.ParamByName('desc').AsString := frmInformation.mnDescription.Text;
        DataModule1.SQLQuery1.Params.ParamByName('date').AsString := DateTimeToStr(CurrentTime);
        DataModule1.SQLQuery1.ExecSQL;
        DataModule1.SQLTransaction1.Commit;
        // FIX: only treat the dialog as successful when the insert committed.
        ModalResult := mrOk;

         except
    on E: Exception do
    begin
      // Rollback in case of error to keep database consistent
          DataModule1.SQLTransaction1.Rollback;
      ShowMessage('Error saving data: ' + E.Message);
      ModalResult := mrNone;
    end;
     end;

  end;

procedure TfrmInformation.cboFilterTypeChange(Sender: TObject);
var
  line:Integer;
begin
  for line:=0 to mnDescription.Lines.Count-1 do
  begin
  if  Pos('Type is ',mnDescription.Lines[line])>0 then
  begin
   mnDescription.Lines.Delete(line);
   mnDescription.lines.Insert(line,'Filter Type is '+cboFilterType.Items[cbofilterType.ItemIndex]);
  end

  end;
end;

procedure TfrmInformation.FormActivate(Sender: TObject);
begin
txtCustomer.Clear;
  mnDescription.Clear;
  cboFilterType.ItemIndex:=0;
   mskFilterName.Text:='';
end;



end.

