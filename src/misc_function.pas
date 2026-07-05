unit misc_function;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,math;
   type
   Convert_result=record
     center,span:Real;

   end;
   function convert(fcenter,fspan,units_f,uints_S:String;high_low:Boolean):Convert_result;
procedure WriteToFile(filename:string;const S: string);
function vswr_calculation(RL:Real):Real;
function Filter_Q(Fc,Span:Real):Real;
function ShapeFactor(BW_60dB, BW_3dB: Real): Real;

implementation
 function convert(fcenter,fspan,units_f,uints_S:String;high_low:Boolean):Convert_result;
 var
   fc,fs,multiplier:real;
 begin
   Result.span:=0;Result.center:=0;
   multiplier:=1;
   try
   case units_f of //units of the fcenter
   'Hz': multiplier:=1;
   'KHz':multiplier:=1000;
   'MHz':Multiplier:=1000000;
   else
  raise Exception.Create('Unknown frequency unit: ' + units_f);
   end;
   fc:=StrToFloat(fcenter);//is fhigh
   fc:=fc*multiplier;
   case uints_S of   //units of fspan
   'Hz': multiplier:=1;
   'KHz':multiplier:=1000;
   'MHz':Multiplier:=1000000;
     else
  raise Exception.Create('Unknown frequency unit: ' + uints_S);
   end;
   fs:=StrToFloat(fspan);//is flow
   fs:=fs*multiplier;
   //if high low
   if high_low then begin //fhigh flow
   Result.center:=(fc+fs)/2;
   Result.span:=fc-fs;
   end
   else
   begin
   Result.center:=fc;
   Result.span:=fs;
    end;
   Except
   on E: EConvertError do
   raise exception.Create('Error in convertion '+E.message);
   on E:Exception do
   raise exception.Create(E.message);
 end;

 end;
procedure WriteToFile(filename:string;const S: string);
var
  F: TextFile;
begin
  filename:=fileName+'.csv';
try
  AssignFile(F,  GetUserDir + 'Desktop' + PathDelim +  filename);
try
  if FileExists(GetUserDir + 'Desktop' + PathDelim + filename) then
    Append(F)
  else
    Rewrite(F);
  
  Writeln(F, S);
  flush(F);
  finally
  CloseFile(F);
end;
  Except
  on E: Exception do
  raise exception.create('File Error I/O : '+E.Message);
end;

end;

     function vswr_calculation(RL:Real):Real;
begin
Result:=(1+power(10,-(Abs(RL)/20)))/((1-power(10,-(Abs(RL)/20))));
end;
     function Filter_Q(Fc,Span:Real):Real;
begin
if span>0 then
Result:=Fc/span
else Result:=0;

end;
     function ShapeFactor(BW_60dB, BW_3dB: Real): Real;
begin
  if BW_3dB > 0 then Result := BW_60dB / BW_3dB else Result := 0;
end;

end.



