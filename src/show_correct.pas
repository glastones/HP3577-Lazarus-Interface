unit Show_correct;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBGrids, StdCtrls,
  DBCtrls, Menus, DataBaseModule, DB, SQLDB;//when you have databases add it


type

  { TfrmShow_correct }

  TfrmShow_correct = class(TForm)
    cboName: TComboBox;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    DBNavigator1: TDBNavigator;
    Label1: TLabel;
    procedure cboNameChange(Sender: TObject);
    procedure DBNavigator1Click(Sender: TObject; Button: TDBNavButtonType);

    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);


    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure QueryAfterPost(DataSet: TDataSet);
    procedure QueryOnNewRecord(DataSet: TDataSet);

  private

  public

  end;

var
  frmShow_correct: TfrmShow_correct;

implementation
 uses Filter_parameters;
{$R *.lfm}

{ TfrmShow_correct }


procedure TfrmShow_correct.FormCreate(Sender: TObject);
begin

  dbgrid1.Visible := false;
  dbgrid2.Visible := false;

  // Enable insert
  DBNavigator1.VisibleButtons := DBNavigator1.VisibleButtons + [nbInsert];
  cboName.Items.Clear;
 try
   DataModule1.connecting;
  Except
   on E:exception do
   ShowMessage (E.Message);
  end;

 cboName.Items.Assign(DataModule1.ReadFilters);
  DataModule1.SQLQuery1.AfterPost := @QueryAfterPost;
  DataModule1.SQLQuery1.AfterDelete := @QueryAfterPost;
  DataModule1.SQLQuery1.OnNewRecord := @QueryOnNewRecord;
  
  DataModule1.SQLQuery2.AfterPost := @QueryAfterPost;
  DataModule1.SQLQuery2.AfterDelete := @QueryAfterPost;
  DataModule1.SQLQuery2.OnNewRecord := @QueryOnNewRecord;

  frmShow_correct.top:=(Screen.DesktopHeight-frmShow_correct.Height) div 2;
  frmShow_correct.left:=(screen.DesktopWidth-frmShow_correct.Width)div 2;
end;

procedure TfrmShow_correct.QueryAfterPost(DataSet: TDataSet);
begin
  // Autosave after post (Post ή Delete)
  if DataSet is TSQLQuery then
  begin
     if DataSet.IsEmpty then Exit; //if dataset is Null
      try
    TSQLQuery(DataSet).ApplyUpdates;
    DataModule1.SQLTransaction1.CommitRetaining;
     except
      on E: Exception do
      begin
        // in case of failed rollback
        DataModule1.SQLTransaction1.RollbackRetaining;
        ShowMessage('Error When try to Save : ' + E.Message);
      end;
        end;
  end;
end;

procedure TfrmShow_correct.QueryOnNewRecord(DataSet: TDataSet);
var
  DatabaseFiled:TField;
   CurrentTime: TDateTime;
begin
  CurrentTime:=now;
  // Auto fill the new record
  if (DataSet = DataModule1.SQLQuery2) and (cboName.ItemIndex > -1) then
  begin
    // Unlock the readonly
    DataSet.FieldByName('filter_name').ReadOnly := False;
    DataSet.FieldByName('filter_name').AsString := Trim(cboName.Text);
    DataSet.FieldByName('filter_name').ReadOnly := True; // locking
    DatabaseFiled:=DataSet.FindField('date_created');
    if Assigned(DatabaseFiled) then
    begin
    DataSet.FieldByName('date_created').ReadOnly := False;
    DataSet.FieldByName('date_created').AsDateTime := CurrentTime;
    DataSet.FieldByName('date_created').ReadOnly := True;
    end;

  end;
end;

procedure TfrmShow_correct.FormDestroy(Sender: TObject);
begin

  DataModule1.SQLQuery1.AfterPost := nil;
  DataModule1.SQLQuery1.AfterDelete := nil;
  DataModule1.SQLQuery1.OnNewRecord := nil;
  
  DataModule1.SQLQuery2.AfterPost := nil;
  DataModule1.SQLQuery2.AfterDelete := nil;
  DataModule1.SQLQuery2.OnNewRecord := nil;
end;

procedure TfrmShow_correct.FormShow(Sender: TObject);
begin //sometime loose the new filters. So we refresh the list.
  cboName.Items.Assign(DataModule1.ReadFilters);
end;

procedure TfrmShow_correct.cboNameChange(Sender: TObject);
 var
   i:Integer;
    FieldName :String;
begin

//Show the grids
dbgrid1.Visible:=True;
dbgrid2.Visible:=True;

// Clear all SQL text
  DataModule1.SQLQuery1.SQL.Clear;
  DataModule1.SQLQuery2.SQL.Clear;
   // Check close if any open exist for security
  DataModule1.SQLQuery1.Close;
  DataModule1.SQLQuery2.Close;
  // If not connected, connect
  if not DataModule1.SQLite3Connection1.Connected then
    DataModule1.SQLite3Connection1.Open;

  // Use a transaction for data integrity
  DataModule1.SQLTransaction1.Active := True;



  // Set SQL commands
  DataModule1.SQLQuery1.SQL.Text := 'SELECT * FROM filters WHERE TRIM(filter_name) = TRIM(:filter_name);';
  // FIX: order by measurement_type then param_index so the normalized rows read
  // logically (otherwise they interleave by id and look jumbled/"wrong").
  DataModule1.SQLQuery2.SQL.Text := 'SELECT * FROM measurement_params WHERE TRIM(filter_name) = TRIM(:filter_name) ORDER BY measurement_code, param_index;';

  // Pass parameters
  DataModule1.SQLQuery1.ParamByName('filter_name').AsString := Trim(cboName.Text);
  DataModule1.SQLQuery2.ParamByName('filter_name').AsString := Trim(cboName.Text);

  // Open Queries
  DataModule1.SQLQuery1.Open;
  DataModule1.SQLQuery2.Open;

  // Link DataSets to DataSources
  DataModule1.DataSource1.DataSet := DataModule1.SQLQuery1;
  DataModule1.DataSource2.DataSet := DataModule1.SQLQuery2;

  // Link DBGrids to DataSources
  DBGrid1.DataSource := DataModule1.DataSource1;
  DBGrid2.DataSource := DataModule1.DataSource2;

  // Lock the columns in Grid for the normalized schema (one row per parameter)
  for I := 0 to DBGrid2.Columns.Count - 1 do
  begin
    FieldName := LowerCase(DBGrid2.Columns[I].FieldName);

    if (FieldName = 'id') or
       (FieldName = 'filter_name') or
       (FieldName = 'measurement_type') or
       (FieldName = 'date_created') or
       (FieldName = 'param_index') or
       (FieldName = 'name')  or
       (FieldName = 'unit') then
    begin
      DBGrid2.Columns[I].ReadOnly := True;
      DBGrid2.Columns[I].Title.Font.Style := [fsItalic];
    end
    else
    begin
      // name, value, unit -> editable
      DBGrid2.Columns[I].ReadOnly := False;
    end;
  end;
  if DataModule1.SQLQuery2.IsEmpty then    DBNavigator1.VisibleButtons := DBNavigator1.VisibleButtons - [nbEdit]
  else DBNavigator1.VisibleButtons := DBNavigator1.VisibleButtons + [nbEdit];
end;

procedure TfrmShow_correct.DBNavigator1Click(Sender: TObject;
  Button: TDBNavButtonType);
begin
  if Button=nbInsert then
  begin
       Filter_parameters.frmParameters.FormMode:= fmEdit;
    if Filter_parameters.frmParameters.ShowModal=MrOk then
    begin
    if Assigned(Cboname.OnChange) then
      cboname.OnChange(Cboname);
    end;
     end;
        end;




procedure TfrmShow_correct.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin

  //release
  datamodule1.release(True);
   CloseAction:=CloseAction;
end;


   end.
