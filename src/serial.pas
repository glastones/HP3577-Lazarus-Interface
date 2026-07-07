unit Serial;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazSerial,lazsynaser,Forms,inifiles;

type

  { TSerials }

  TSerials = class(TDataModule)
    LazSerial1: TLazSerial;
    procedure DataModuleCreate(Sender: TObject);
     Function connect_dialog:Boolean;
     Procedure close;
  private
       // Removed data TStringList to avoid conflict with synchronous reading in show unit
  public

  end;

var
  Serials: TSerials;

implementation

{$R *.lfm}

{ TSerials }

procedure TSerials.DataModuleCreate(Sender: TObject);
begin
    LazSerial1.Close; //close for safety
    LazSerial1.BaudRate:=br__9600;       //default speed
    LazSerial1.Active := False; //non active
end;

   Function TSerials.connect_dialog:Boolean;
   var
     configFile:TInifile;
     comport:String;
     found:Boolean;
     PortList:TStringList;
     i:smallInt;
   begin
    Result:=False; found:=false;
    portList:=TstringList.Create;
    portList.CommaText:=GetSerialPortNames; //get all serials.
    self.LazSerial1.Close; //close for safety
    self.LazSerial1.BaudRate :=br__9600;     //default speed
    self.LazSerial1.Active := False; //non active
    configFile:=TIniFile.Create(ExtractFilePath(application.Params[0])+'settings.ini');
    if FileExists(ExtractFilePath(application.Params[0])+'settings.ini') then
     begin
      comport:=Trim(configFile.ReadString('Setting','Port',''));
     if comport<>'' then
     self.LazSerial1.Device:=comport;
     end;
     found:=False;
     for i:=0 to portlist.Count-1 do begin
     if   Pos(AnsiUpperCase(comport), AnsiUpperCase(portlist[i])) > 0 then begin found:=True;break; end
        end;
     if not found then begin
     if FileExists(ExtractFilePath(application.Params[0])+'settings.ini') then
     DeleteFile(ExtractFilePath(application.Params[0])+'settings.ini'); //wrong data found
      if portlist.Count>0 then  begin
     self.LazSerial1.Device:=portlist.Strings[0];
     self.LazSerial1.ShowSetupDialog; //user setup
     configFile.WriteString('Setting','Port',serials.LazSerial1.Device);//save the new data
  end
     else
     begin
    raise Exception.Create('No serial ports found on the system');
  end;
end;

   try
    try
    self.LazSerial1.Active := True; //make it active
   // self.LazSerial1.Open;       // open the communication may be open from activate.
    except
    on E: EInOutError do
    begin
     Result:=False;
      self.LazSerial1.Active := False;
      self.LazSerial1.Close;
      raise exception.Create('Serial is Busy. Could not open Serial Port '+E.Message);
      Exit;
    end;
    on E:Exception do
    begin
    self.LazSerial1.Active := False;
    self.LazSerial1.Close;
    raise exception.Create(E.Message);
    Exit;
    end;
    end;
    finally
    configFile.Free;
    portList.Free;
    end;
    Result:=True;
  end;
        Procedure TSerials.close;
        begin

           //purge the RS232 connection
         Serials.LazSerial1.SynSer.Purge;
         //close the RS232
          self.LazSerial1.Active:=False;
          self.LazSerial1.Close;

        end;

end.

