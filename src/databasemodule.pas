unit DataBaseModule;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, DB,Forms,Dialogs;

type


  TMeasParam = record
    Name : string;     // parameter label, e.g. 'Center Frequency'
    Value: Double;     // numeric value
    AUnit: string;     // unit text, e.g. 'Hz', 'dB', 'us', 'Min'
    show_to_user:Integer; //if must be show to user.
    send_to_vna:Integer;//parameter to send to the vna
    measurement_Type:String;
    measurement_code:Integer;//save measurment code from cbomeasurement
    Result_code:Integer;//save value for final comparison and pass fail
    end;
  filter_information= record
    name:String;
    customer:String;
    filter_type:Integer;
    description:String;
  end;

  TMeasParams = array of TMeasParam;
  filter_info=Filter_information;

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLQuery2: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
    procedure connecting;
    function ReadFilters:TStringList;
    function  CopyFilter(const AOld, ANew: string): Boolean;
    procedure release(second:Boolean);
    procedure filter_delete(AFilter: string);
    procedure SaveMeasurement(const AFilter{, AMeasType}: string; const AParams: TMeasParams);
    function ReadMeasurementTypes(const AFilter: string): TStringList;
    function ReadMeasurement(const AFilter, AMeasType: string): TMeasParams;
    function ReadMeasurement_Typo(Measurment,AFilter: string;index:smallInt): String;
    function read_show(AFilter:String):TMeasParams;
    function read_vna(AFilter:String):TMeasParams;
    function variable_for_passFail(AFilter:String):TMeasParams;
     function ReadFilterInfo(AFilter:String):Filter_info;
     procedure ReplaceMeasurement(const AFilter{, AMeasType}: string; const AParams: TMeasParams);
  private
     //measurement_indexing:Integer;
  public
   param_index:Array[1..10] of Integer;

  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.lfm}

{ TDataModule1 }

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin

  // FIX: ExtractFilePath already returns a trailing path delimiter, so do not
  // add another '\'. The doubled separator was inconsistent with the FileExists
  // check in connecting() and is not portable.
  SQLite3Connection1.DatabaseName:=ExtractFilePath(Application.ExeName)+'Simply_VNA_Full.db';
  // FIX: enable foreign keys at the CONNECTION level (outside any transaction),
  // so ON DELETE CASCADE actually works. A "PRAGMA foreign_keys=ON" issued after
  // a transaction has started is silently ignored by SQLite.
  if SQLite3Connection1.Params.IndexOfName('foreign_keys') < 0 then
    SQLite3Connection1.Params.Add('foreign_keys=ON');
  connecting;

end;
procedure TDataModule1.connecting;
begin
  if not FileExists(ExtractFilePath(Application.ExeName)+'Simply_VNA_Full.db') then
    // FIX: raise only (the old 'halt' after raise was dead code and would have
    // killed the whole app). Callers wrap this in try/except and report it.
    raise Exception.Create('Database is missing: Simply_VNA_Full.db');

  // FIX: same path spelling as the existence check above (no doubled '\').
 self.SQLite3Connection1.DatabaseName:=ExtractFilePath(Application.ExeName)+'Simply_VNA_Full.db';

  try
    if not self.SQLite3Connection1.Connected then
      begin
      self.SQLite3Connection1.Open;
    self.SQLite3Connection1.ExecuteDirect('PRAGMA foreign_keys = ON;');
end;
    self.SQLTransaction1.Active := True;
    self.SQLQuery1.Close;
  except
    on E: Exception do
      raise Exception.Create('Could not connect to database: ' + E.Message);
  end;
  self.SQLQuery1.SQL.Clear;
end;
   function TDataModule1.ReadFilters:TStringList;
   begin
     Result:=TStringList.Create;
    try
      self.connecting;
      Except
      on E: Exception do
      begin
      // FIX: free the list before leaving (was leaked) and re-raise. The old
      // 'Result.Free' after 'raise' was dead code and never ran.
      Result.Free;
      raise Exception.Create('DataBase Not Found');
      end;
     end;
     self.SQLQuery1.SQL.Text := 'SELECT filter_name FROM filters';
//open query
self.SQLQuery1.Open;
//read until the end of data
while not (self.SQLQuery1.EOF) do
begin
//request from the main table the name of the filter and put it on the list.
Result.Add(self.SQLQuery1.FieldByName('filter_name').AsString);
//go to the next
self.SQLQuery1.Next;
end;
//close query
self.SQLQuery1.Close;
//release the database
self.SQLTransaction1.Commit;
    end;
   function TDataModule1.ReadFilterInfo(AFilter:String):Filter_info;
   begin

    try
      self.connecting;
      Except
      on E: Exception do
      begin
      // FIX: free the list before leaving (was leaked) and re-raise. The old
      // 'Result.Free' after 'raise' was dead code and never ran.
      raise Exception.Create('DataBase Not Found');
      end;
     end;
     self.SQLQuery1.SQL.Text := 'SELECT filter_name,customer,filter_type,description FROM filters where filter_name=:f order by filter_name';
      self.SQLQuery1.ParamByName('f').AsString   := AFilter;
//open query
self.SQLQuery1.Open;
//read until the end of data
while not (self.SQLQuery1.EOF) do
begin
//request from the main table the name of the filter and put it on the list.
Result.name:=self.SQLQuery1.FieldByName('filter_name').AsString;
Result.customer:=self.SQLQuery1.FieldByName('customer').AsString;
Result.filter_type:=self.SQLQuery1.FieldByName('filter_type').AsInteger;
Result.description:=self.SQLQuery1.FieldByName('description').AsString;
//go to the next
self.SQLQuery1.Next;
end;
//close query
self.SQLQuery1.Close;
//release the database
self.SQLTransaction1.Commit;
    end;
 function TDataModule1.CopyFilter(const AOld, ANew: string): Boolean;
 var
   CurrentTime: string;
 begin
  Result := False;
  self.connecting;

  try
    CurrentTime:=DateTimeToStr(now);
    self.SQLQuery1.Close;
    self.SQLQuery1.SQL.Text :=
      'INSERT INTO filters (filter_name, customer, filter_type, description, date_created) ' +
      'SELECT :new, customer, filter_type, description, :d FROM filters WHERE filter_name = :old';
    self.SQLQuery1.ParamByName('new').AsString   := ANew;
    self.SQLQuery1.ParamByName('old').AsString   := AOld;
    self.SQLQuery1.ParamByName('d').AsString    := CurrentTime;  //now
    self.SQLQuery1.ExecSQL;

    self.SQLQuery1.Close;
    self.SQLQuery1.SQL.Text :=
      'INSERT INTO measurement_params ' +
      '(filter_name, measurement_type, param_index, name, value, unit,  date_created) ' +
      'SELECT :new, measurement_type, param_index, name, value, unit, :d ' +
      'FROM measurement_params WHERE filter_name = :old';
    self.SQLQuery1.ParamByName('new').AsString   := ANew;
    self.SQLQuery1.ParamByName('old').AsString   := AOld;
    self.SQLQuery1.ParamByName('d').AsString   :=CurrentTime;  //now
    self.SQLQuery1.ExecSQL;


    self.SQLTransaction1.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      self.SQLTransaction1.Rollback;
      raise Exception.Create('CopyFilter failed: ' + E.Message);
    end;
  end;
end;


  //finaly release all
   procedure TDataModule1.release(second:Boolean);
    begin
      // 1. Close active datasets (Queries/Tables)
            if second then begin //2
             self.SQLQuery1.SQL.Clear;
             self.SQLQuery2.SQL.Clear;
             self.SQLQuery1.Close;
             self.SQLQuery2.Close;
  end
            else //only one
            begin
   self.SQLQuery1.SQL.Clear;
  self.SQLQuery1.Close;
                 end;

    end;

  procedure TDataModule1.filter_delete(AFilter: string);
  begin
    self.connecting;
    try
      // FIX: delete child rows explicitly first, then the parent. This is
      // correct whether or not foreign_keys/CASCADE is active, and never leaves
      // orphaned measurement_params rows.
      self.SQLQuery1.Close;
      self.SQLQuery1.SQL.Text := 'DELETE FROM measurement_params WHERE filter_name = :f';
      self.SQLQuery1.ParamByName('f').AsString := AFilter;
      self.SQLQuery1.ExecSQL;

      self.SQLQuery1.Close;
      self.SQLQuery1.SQL.Text := 'DELETE FROM filters WHERE filter_name = :f';
      self.SQLQuery1.ParamByName('f').AsString := AFilter;
      self.SQLQuery1.ExecSQL;

      self.SQLTransaction1.Commit;
    except
      on E: Exception do
      begin
        self.SQLTransaction1.Rollback;
        raise Exception.Create('DeleteFilter failed: ' + E.Message);
      end;
    end;
  end;
      // Save (replace) all parameters of one measurement. AParams may hold any N.
procedure TDataModule1.SaveMeasurement(const AFilter{, AMeasType}: string; const AParams: TMeasParams);
var
  i: Integer;
  CurrentTime: String;
begin
  self.connecting;
  try
    CurrentTime:=DateTimeToStr(now);
     self.SQLQuery1.Close;
    self.SQLQuery1.SQL.Text :=
      'INSERT INTO measurement_params ' +
      '(filter_name, measurement_type, param_index, name, value, unit,  date_created, Show_to_user,send_to_vna,measurement_code,Var_for_Result  ) ' +
      'VALUES (:f, :t, :idx, :n, :v, :u, :d, :user, :vna , :code, :var)';
     for i := Low(AParams) to High(AParams) do
    begin
      self.SQLQuery1.ParamByName('f').AsString         := AFilter;
      self.SQLQuery1.ParamByName('t').AsString         := AParams[i].measurement_Type;//AMeasType;
      self.SQLQuery1.ParamByName('idx').AsInteger      := i + 1;
      self.SQLQuery1.ParamByName('n').AsString         := AParams[i].Name;
      self.SQLQuery1.ParamByName('v').AsFloat          := AParams[i].Value;
      self.SQLQuery1.ParamByName('u').AsString         := AParams[i].AUnit;
      self.SQLQuery1.ParamByName('user').AsInteger     := AParams[i].show_to_user;
      self.SQLQuery1.ParamByName('vna').AsInteger      := AParams[i].send_to_vna;
      self.SQLQuery1.ParamByName('code').AsInteger     := AParams[i].measurement_code;
      self.SQLQuery1.ParamByName('var').AsInteger      := AParams[i].Result_code;
      self.SQLQuery1.ParamByName('d').AsString         := CurrentTime;
      self.SQLQuery1.ExecSQL;
    end;
      self.SQLTransaction1.Commit;
  except
    on E: Exception do
    begin
      self.SQLTransaction1.Rollback;
      raise Exception.Create('SaveMeasurement failed: ' + E.Message);
    end;
  end;
end;
   // replace all parameters of one measurement. AParams may hold any N.
procedure TDataModule1.ReplaceMeasurement(const AFilter{, AMeasType}: string; const AParams: TMeasParams);
var
  i: Integer;
  CurrentTime: String;
begin
  self.connecting;
  try
    CurrentTime:=DateTimeToStr(now);
    //make new routine for replace
    // make the save idempendent: clear this measurement's old rows first
     self.SQLQuery1.Close;
    self.SQLQuery1.SQL.Text :=
      'DELETE FROM measurement_params WHERE filter_name = :f AND measurement_type = :t';
    self.SQLQuery1.ParamByName('f').AsString := AFilter;
    self.SQLQuery1.ParamByName('t').AsString := AParams[Low(AParams)].measurement_Type;//AMeasType;
    self.SQLQuery1.ExecSQL;

    self.SQLQuery1.Close;
    self.SQLQuery1.SQL.Text :=
      'INSERT INTO measurement_params ' +
      '(filter_name, measurement_type, param_index, name, value, unit,  date_created, Show_to_user,send_to_vna,measurement_code,Var_for_Result  ) ' +
      'VALUES (:f, :t, :idx, :n, :v, :u, :d, :user, :vna , :code, :var)';
     for i := Low(AParams) to High(AParams) do
    begin
      self.SQLQuery1.ParamByName('f').AsString         := AFilter;
      self.SQLQuery1.ParamByName('t').AsString         := AParams[i].measurement_Type;//AMeasType;
      self.SQLQuery1.ParamByName('idx').AsInteger      := i + 1;
      self.SQLQuery1.ParamByName('n').AsString         := AParams[i].Name;
      self.SQLQuery1.ParamByName('v').AsFloat          := AParams[i].Value;
      self.SQLQuery1.ParamByName('u').AsString         := AParams[i].AUnit;
      self.SQLQuery1.ParamByName('user').AsInteger     := AParams[i].show_to_user;
      self.SQLQuery1.ParamByName('vna').AsInteger      := AParams[i].send_to_vna;
      self.SQLQuery1.ParamByName('code').AsInteger     := AParams[i].measurement_code;
      self.SQLQuery1.ParamByName('var').AsInteger      := AParams[i].Result_code;
      self.SQLQuery1.ParamByName('d').AsString         := CurrentTime;
      self.SQLQuery1.ExecSQL;
    end;

    self.SQLTransaction1.Commit;
  except
    on E: Exception do
    begin
      self.SQLTransaction1.Rollback;
      raise Exception.Create('SaveMeasurement failed: ' + E.Message);
    end;
  end;
end;

function TDataModule1.ReadMeasurement(const AFilter, AMeasType: string): TMeasParams;
var
index:smallInt;
begin
  Result := nil;
  index:=1;
  //SetLength(Result, 0);
  self.connecting;
 self.SQLQuery1.Close;
 self.SQLQuery1.SQL.Text :=
    'SELECT name, value, unit  FROM measurement_params ' +
    'WHERE filter_name = :f AND measurement_type = :t ORDER BY param_index';
 self.SQLQuery1.ParamByName('f').AsString := AFilter;
 self.SQLQuery1.ParamByName('t').AsString := AMeasType;
 self.SQLQuery1.Open;
  while not self.SQLQuery1.EOF do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Name  :=self.SQLQuery1.FieldByName('name').AsString;
    Result[High(Result)].Value :=self.SQLQuery1.FieldByName('value').AsFloat;
    Result[High(Result)].AUnit :=self.SQLQuery1.FieldByName('unit').AsString;
    param_index[index]:=index;
    inc(index);
   self.SQLQuery1.Next;
  end;
 self.SQLQuery1.Close;
end;

function TDataModule1.ReadMeasurementTypes(const AFilter: string): TStringList;
begin
  Result := TStringList.Create;
 self.connecting;
 self.SQLQuery1.Close;
 self.SQLQuery1.SQL.Text :=
    'SELECT DISTINCT measurement_type FROM measurement_params ' +
    'WHERE filter_name = :f ORDER BY measurement_type';
 self.SQLQuery1.ParamByName('f').AsString := AFilter;
 self.SQLQuery1.Open;
  while not self.SQLQuery1.EOF do
  begin
    Result.Add(self.SQLQuery1.FieldByName('measurement_type').AsString);
   self.SQLQuery1.Next;
  end;
 self.SQLQuery1.Close;
end;
function TDataModule1.ReadMeasurement_Typo(Measurment,AFilter: string;index:smallInt): String;
begin
 Result:='';
 self.connecting;
 try
 self.SQLQuery1.Close;
 self.SQLQuery1.SQL.Text :='SELECT value,unit FROM measurement_params '+
 'WHERE measurement_type = :m and filter_name = :f and  param_index = :i';
 self.SQLQuery1.ParamByName('f').AsString := AFilter;
 self.SQLQuery1.ParamByName('m').AsString := Measurment;
 self.SQLQuery1.ParamByName('i').AsInteger := index;
 self.SQLQuery1.Open;
     if not self.SQLQuery1.EOF then
       try
       Result:=self.SQLQuery1.FieldByName('value').AsString+self.SQLQuery1.FieldByName('unit').AsString;
       except
        on E: Exception do
        begin
          raise Exception.Create('Error reading measurement field: ' + E.Message);
      end;

       end;
    finally
     self.SQLQuery1.Close;
  end;
 end;
    function TDataModule1.read_show(AFilter:String):TMeasParams;
    begin
    Result:=nil;
     self.connecting;
 self.SQLQuery1.Close;
 self.SQLQuery1.SQL.Text :='select measurement_type,name,value,unit,measurement_code from measurement_params ' +
 'WHERE show_to_user=1 and filter_name = :f  order by measurement_code';
  self.SQLQuery1.ParamByName('f').AsString := AFilter;
  self.SQLQuery1.Open;
  while not self.SQLQuery1.EOF do
  begin
   SetLength(Result, Length(Result) + 1);
    Result[High(Result)].measurement_Type:=self.SQLQuery1.FieldByName('measurement_type').AsString;
    Result[High(Result)].Name:=self.SQLQuery1.FieldByName('name').AsString;
    Result[High(Result)].Value:=self.SQLQuery1.FieldByName('value').AsFloat;
    Result[High(Result)].AUnit:=self.SQLQuery1.FieldByName('unit').AsString;
     Result[High(Result)].measurement_code:=self.SQLQuery1.FieldByName('measurement_code').AsInteger;


   self.SQLQuery1.Next;
  end;
 self.SQLQuery1.Close;
     end;
             function TDataModule1.read_vna(AFilter:String):TMeasParams;
    begin

    Result:=nil;
     self.connecting;
 self.SQLQuery1.Close;
 self.SQLQuery1.SQL.Text :='select measurement_type,name,value,unit,measurement_code from measurement_params ' +
 'WHERE send_to_vna=1 and filter_name = :f  order by measurement_code';
  self.SQLQuery1.ParamByName('f').AsString := AFilter;
  self.SQLQuery1.Open;
  while not self.SQLQuery1.EOF do
  begin
   SetLength(Result, Length(Result) + 1);
    Result[High(Result)].measurement_Type:=self.SQLQuery1.FieldByName('measurement_type').AsString;
    Result[High(Result)].Name:=self.SQLQuery1.FieldByName('name').AsString;
    Result[High(Result)].Value:=self.SQLQuery1.FieldByName('value').AsFloat;
    Result[High(Result)].AUnit:=self.SQLQuery1.FieldByName('unit').AsString;
    Result[High(Result)].measurement_code:=self.SQLQuery1.FieldByName('measurement_code').AsInteger;


   self.SQLQuery1.Next;
  end;
 self.SQLQuery1.Close;
     end;
    function TDataModule1.variable_for_passFail(AFilter:String):TMeasParams;
    begin

    Result:=nil;
     self.connecting;
 self.SQLQuery1.Close;
 self.SQLQuery1.SQL.Text :='select measurement_type,name,value,unit,measurement_code from measurement_params ' +
 'WHERE Var_for_Result=1 and filter_name = :f  order by measurement_code';
  self.SQLQuery1.ParamByName('f').AsString := AFilter;
  self.SQLQuery1.Open;
  while not self.SQLQuery1.EOF do
  begin
   SetLength(Result, Length(Result) + 1);
    Result[High(Result)].measurement_Type:=self.SQLQuery1.FieldByName('measurement_type').AsString;
    Result[High(Result)].Name:=self.SQLQuery1.FieldByName('name').AsString;
    Result[High(Result)].Value:=self.SQLQuery1.FieldByName('value').AsFloat;
    Result[High(Result)].AUnit:=self.SQLQuery1.FieldByName('unit').AsString;
     Result[High(Result)].measurement_code:=self.SQLQuery1.FieldByName('measurement_code').AsInteger;


   self.SQLQuery1.Next;
  end;
 self.SQLQuery1.Close;
     end;
end.

