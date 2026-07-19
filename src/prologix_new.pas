unit prologix;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,Serial,Forms,LazSerial,Dialogs,inifiles;
     Function config:Boolean;
     Function close:Boolean;
     procedure Write_Data(data:String);
     function read_data(sleep_time:Integer):Real;
      function isopen:boolean;
      procedure release;
      procedure connect;
implementation
uses hp3577;
var
  configExecuted:Boolean;
Function config:Boolean;
 var
   configFile:TInifile;
   R:String;
   x,status:Integer;
   found:Boolean;
begin
 found:=False;
 status:=0;
 if configExecuted then begin Result:=True; Exit;  end;
 try
 configFile:=TIniFile.Create(ExtractFilePath(application.Params[0])+'settings.ini');
 // Make Prologix Controller
   Serials.LazSerial1.WriteData('++mode 1' + #10);
     // Enable automatic read after query commands
     Serials.LazSerial1.WriteData('++auto 1'+ #10);
    // set address of the instrument
 // Serial.WriteData('++addr 22' + #10);
    // Enable EOI line signaling (standard for GPIB transfers)  CR+ LF
     Serials.LazSerial1.WriteData('++eoi 1' + #10);
   // IMPORTANT: LF only termination (required for HP 3577A reliability)
   // NOTE: the comment says "LF only" but Prologix '++eos 3' = append NOTHING.
   // LF-only would be '++eos 2'. Left unchanged because the current value
   // matches the working firmware/instrument timing - verify on hardware before
   // changing, as GPIB termination affects reliability.
     Serials.LazSerial1.WriteData('++eos 3' + #10);
     // Make Prologix Clear the bus
     Serials.LazSerial1.WriteData('++ifc' + #10);
  // Serial Polling. Send and receive answer. If 0 then
  //Serial.WriteData('++spoll'+ #10);
  //wait for instrument  response
  Sleep(50);

  if  not Serials.connect_dialog then begin ShowMessage('Error With the Serial Port ');Result:=False;Exit; end;
  Except
    on E: EInOutError do
    begin
     Result:=False;
     ShowMessage(E.Message);
     Exit;
    end;
    on E:Exception do begin
     Result:=False;
     ShowMessage(E.Message);
     Exit;
     end;

  end;
 Serials.LazSerial1.WriteData('++ver'+#10);
 sleep(100);
 R:=Serials.LazSerial1.ReadData;
  status:=Length(R);
  //activated in final program only

 if status=0 then begin
  Showmessage('The Prologix is not connected.'+slineBreak+' Ensure connection and try Again');
  Result := False;
  if FileExists(ExtractFilePath(application.Params[0])+'settings.ini') then
  DeleteFile(ExtractFilePath(application.Params[0])+'settings.ini');
  Exit;
 end;
try
    try
     connect;
     //check if vna address is saved already
     if FileExists(ExtractFilePath(application.Params[0])+'settings.ini')then
     x:=configFile.ReadInteger('VNA','address',0);
     if x<>0 then //if address exist check if is valid
     begin
     Serials.LazSerial1.WriteData('++addr ' + IntToStr(x)+ #10);
     //purge the RS232 connection
     Serials.LazSerial1.SynSer.Purge;
     // HP3577A read ID
     Serials.LazSerial1.WriteData('ID?'+sLineBreak);
     R:='';
     R:=Serials.LazSerial1.ReadData;
     if R.Contains('TESTSET') then
      begin  //machine answer all ok
      Result:=True;
      found := True;
      end;
     end
     else
     //find the instrument
    for x := 1 to 30 do
    begin
       Serials.LazSerial1.WriteData('++addr ' + IntToStr(x)+ #10);
    //purge the RS232 connection
   Serials.LazSerial1.SynSer.Purge;
   // HP3577A read ID
       serials.LazSerial1.WriteData('ID?'+sLineBreak);
    Sleep(200); // give time to the instrument to execute the command
     R:='';
     R:=   Serials.LazSerial1.ReadData;
     if (not String.IsNullOrEmpty(R)) and (R.Contains('3577')) then
     begin
    //  ShowMessage('FOUND device at address ' + IntToStr(x) );
      if R.Contains('TESTSET') then
      begin
     // ShowMessage('Instrument Found with S-Parameters');
      Result:=True;
      found := True;
      configExecuted:=True;
      if FileExists(ExtractFilePath(application.Params[0])+'settings.ini') then
      configFile.WriteInteger('VNA','address',x);//save the address
      break;
    end;
   end;
      end;
          if not found then
     begin
       ShowMessage('Instrument Not Found');
       Result := False;
      if FileExists(ExtractFilePath(application.Params[0])+'settings.ini')
      then DeleteFile(ExtractFilePath(application.Params[0])+'settings.ini');
       // FIX: return False instead of Application.Terminate.
       Exit;
     end
          else
          begin
    Result:=Found;
    configExecuted:=True;
     end;
    Except
    on E:Exception do
    begin
       ShowMessage('Com is not Configured');
       Result := False;
      if FileExists(ExtractFilePath(application.Params[0])+'settings.ini')
      then DeleteFile(ExtractFilePath(application.Params[0])+'settings.ini');
      prologix.close;
      end;
      end;
    finally
      configfile.Free;
      end;
    end;

         Function close:Boolean;
        begin
          Result:=False;
           Serials.close;
          Result:=True;
        end;

           procedure Write_Data(data:String);
               begin
                if prologix.isopen then
                begin
                 try
                 Serials.LazSerial1.SynSer.Purge; //clear the RS232
                  Serials.LazSerial1.WriteData(data+sLineBreak);
                  sleep(hp3577.sleep_time);

                    except
    on E: exception do
          raise exception.Create('Error '+E.Message);
                 end;
                    end;

               end;

               function read_data(sleep_time:Integer):Real;
               var
                 inputs:String;
                 temp:Integer;
                 value:Real;
                 FS:TFormatSettings;
               begin
                 FS:=DefaultFormatSettings;
                 FS.DecimalSeparator:='.';
                 Result:=0;  temp:=0;
                 inputs:='';  value:=0;
                 sleep(sleep_time);
                  if prologix.isopen then begin
                  repeat
                  inputs:=Serials.LazSerial1.ReadData;
                  if inputs<>'' then break;
                  sleep(sleep_time);
                  inc(temp);
                  until temp>20;
                 try
                 if inputs='' then begin
                 ShowMessage('Error in communication with the HP3577 reading data');
                 Exit;
                 End;
                 temp:=Pos(#13,inputs);
                 if temp>0 then delete(inputs,temp,length(inputs));
                 value:=StrToFloat(trim(inputs),FS);
                 except
                 on E: EConvertError do
                     raise exception.Create('Error in Convertion');
                  on E: exception do
                 raise exception.Create('Error '+E.Message);
                 end;
                 Result:=value;
                 end;
                end;

           function isopen:boolean;
           begin
            if serials.LazSerial1.Active then Result:=True else Result:=False;
            end;
           procedure release;
           begin
           Serials.LazSerial1.WriteData('++loc'+ #10)
           end;
           procedure connect;
           begin
           if isopen then
           begin
             Serials.LazSerial1.WriteData('++clr'+ #10);
             Serials.LazSerial1.WriteData('++ren 1'+ #10);
           end
           else raise exception.Create('Error connected with the prologix after release');
           end;
    initialization
    begin
        configExecuted:=false; //initialize the variable
      end;

end.

