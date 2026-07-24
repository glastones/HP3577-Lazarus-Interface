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
  found:Boolean;
Function config:Boolean;
 var
   R:String;
   x,status:Integer;

  configFile:TInifile;
begin

 status:=0; x:=0;
  if found then Result:=True else begin
  try
  if  not Serials.connect_dialog then begin ShowMessage('Error With the Serial Port ');Result:=False;Exit; end;
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
  //Sleep(50);
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
    connect;
    configFile:=TIniFile.Create(ExtractFilePath(application.Params[0])+'settings.ini');
   if FileExists(ExtractFilePath(application.Params[0])+'settings.ini') then
   x:=configFile.ReadInteger('VNA','Address',0);
   if x=0 then    //file contains wrong information
   DeleteFile(ExtractFilePath(application.Params[0])+'settings.ini')
   else
   begin   //confirm address is correct
    R:='';
     serials.LazSerial1.SynSer.Purge;
     Serials.LazSerial1.WriteData('++addr ' + IntToStr(x)+ #10);
     Serials.LazSerial1.WriteData('ID?'+sLineBreak);
     sleep(100);
     R:=   Serials.LazSerial1.ReadData;
     if (not String.IsNullOrEmpty(R)) and (R.Contains('3577')) then
     found:=True; //instrument responded.
     end;
   if not found then //if answer not found
    for x := 1 to 30 do
    begin
       Serials.LazSerial1.WriteData('++addr ' + IntToStr(x)+ #10);
    //purge the RS232 connection
   Serials.LazSerial1.SynSer.Purge;
   // HP3577A read ID
       Serials.LazSerial1.WriteData('ID?'+sLineBreak);
    Sleep(100); // give time to the instrument to execute the command
     R:='';
     R:=   Serials.LazSerial1.ReadData;
         // if R<>'' then ShowMessage(R+' '+IntToStr(x));
     if (not String.IsNullOrEmpty(R)) and (R.Contains('3577')) then
     begin

    //  ShowMessage('FOUND device at address ' + IntToStr(x) );
      if R.Contains('TESTSET') then
      begin
     configFile.writeInteger('VNA','Address',x);//save the address.
     // ShowMessage('Instrument Found with S-Parameters');
      Result:=True;
      found := True;
      break;
    end;
   end;
      end;
     if not found then
     begin
       ShowMessage('Instrument Not Found');
       Result := False;
       // FIX: return False instead of Application.Terminate.
       Exit;
     end;
    Result:=Found;
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
                  sleep(sleep_time);
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
                  if prologix.isopen then begin
                  repeat
                     sleep(sleep_time);
                  inputs:=Serials.LazSerial1.ReadData;      //special char of prologix

                  until (inputs<>'') or (pos(inputs,#10)>0) or (pos(inputs,'<0>')>0) or (pos(inputs,'16')>0 );
                  try
                   if length(inputs)>20 then inputs:='';
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
      found:=False;
      end;
end.

