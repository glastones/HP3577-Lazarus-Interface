unit hp3577;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,prologix,Dialogs,LCLType,math,controls;
type
  calibrate_variables=record
    call_S11:Real;
    call_S21:Real;
    call_S22:Real;
    cal_GD:Real;
    cal_scale:real;
  end;
calibration_process=Record
IL:Boolean;
S11:Boolean;
S22:Boolean;
GD:boolean;
end;


    function calibrate(fcenter,fspan:real;measurement:SmallInt):Calibrate_variables;
    function IL(fcenter,fspan:Real;types:smallInt):Real;
    function RL(fcenter,fspan:Real;input:smallInt):Real;
    function GroupDelay(Fcenter,Fspan:Real;Type_of_measurment:SmallInt):Real;
    function Ripple(Fcenter,Fspan:Real):Real;
    function center_frequnency_x_db(fcenter,fspan,x:Real):Real;
    function attn_at_Freq(Fcenter,fspan,atten_freq:Real;type_of_measure:smallInt):Real;
    function find_scale(fcenter,fspan:Real):Real;
    function Attenuation_at_stopband(Fcenter,Fspan,low_freq,High_freq,x:Real;left_or_right:smallInt):Real;
    function spurious_ultimate( Fcenter,zero_span,stop_span:real):Real;
function Next125(x: Double): Double;
procedure Marker_AutoScale(Marker1Value, Marker2Value: Double;
  out Scale, Reference: Double);
      function bandwidth(Fcenter,Fspan,x:Real;type_or_measurement:smallInt):Real;
      function bandwidth_x_db(fcenter,fspan,x:Real):Real;

      const sleep_time=250;   //no more than 500ms
      var
            // sleep_time:Integer;
             callibration:Calibrate_variables;
             calibration_proc:Calibration_process;
            implementation
 var

             command:String;

 function calibrate(fcenter,fspan:real;measurement:SmallInt):Calibrate_variables;
var
            temp:real; cal:boolean;
begin
  cal:=False;
  prologix.Write_Data('IPR;BD0;FM1;DCH');//Reset and initialize as fast as possible.
 case measurement of
1:
begin
if not calibration_proc.IL then 
begin
if MessageDlg('Calibration Routine','Please Install the short',mtwarning,[mbYes, mbNo],0)=mrYes then
begin
      cal:=False;
      while not cal do
      begin
        command:='I21;DF7;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MTN;DM1';
        prologix.Write_Data(command);
        Result.call_S21:=prologix.read_data(sleep_time);
        if Result.call_S21<-15 then begin
          ShowMessage('Short is not installed. Installed it and press ok');
          cal:=False;
        end
        else begin
          cal:=True;
          calibration_proc.IL:=True;
        end;
      end;
   end
else calibration_proc.IL:=false;
   end;
   end;

2:
begin
if not calibration_proc.GD then
  begin
  command:='I21;DF1;AP4;BW3;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MKP 0;MP1';
   prologix.Write_Data(command);
   temp:=prologix.read_data(sleep_time);
   command:='I21;DF1;AP4;BW3;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MKP 400;MP1';
   prologix.Write_Data(command);
   Result.cal_GD:=fspan-(prologix.read_data(sleep_time)-temp);
       calibration_proc.GD:=True;
       command:='BW4';//return IF=1KHz
       prologix.Write_Data(command);
  end;
end;
3:
begin
if not calibration_proc.S11 then
  begin
if MessageDlg('Calibration Routine','Leave the port open',mtwarning,[mbYes, mbNo],0)=mrYes then
begin
  command:='I22;DF7;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MTN;DM1';
   prologix.Write_Data(command);
   Result.call_S22:=prologix.read_data(sleep_time);
   command:='I11;DF7;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MTN;DM1';
   prologix.Write_Data(command);
   Result.call_S11:=prologix.read_data(sleep_time);
      calibration_proc.S11:=True;
      calibration_proc.S22:=true;
      end
else
begin
calibration_proc.S11:=False;
calibration_proc.S22:=False;
end;
 end;
end;
end;
   Result.cal_scale:=find_scale(fcenter,fspan);//find the scale and make it reference.
 end;




 function find_scale(fcenter,fspan:Real):Real; //find the scale and make it reference.
 var
             temp:real;
 begin
       command:='I21;DF7;DIV 1 DBR;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MTX;DM1';
       prologix.Write_Data(command);
       temp:=prologix.read_data(sleep_time);
       if temp<=3 then Result:=1
       else Result:=temp-1;//find the scale and make it reference.
 end;

function IL(fcenter,fspan:Real;types:smallInt):Real; //1 IL 2 IL from center
  begin
        Result:=0;
        case types of
0:Begin      command:='I21;DF7;DIV 1 DBR;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MTX;DM1';

      end;
1: begin
     command:='I21;DF7;DIV 1 DBR;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MKP 200;DM1';
    end;
end;

       prologix.Write_Data(command);
      Result:=prologix.read_data(sleep_time)-callibration.call_S21;
        end;
  function RL(fcenter,fspan:Real;input:smallInt):Real; //10=S11 11=S22
   begin
       Result:=0;
case input of
      10://s11
        begin
    command:='I11;DF7;DIV 5 DBR;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MTX;MP1';
    prologix.Write_Data(command);
   Result:=prologix.read_data(sleep_time)-callibration.call_S11;
    end;
      11://s22
        begin
    command:='I22;DF7;DIV 5 DBR;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz;MTX;MP1';
    prologix.Write_Data(command);
    Result:=prologix.read_data(sleep_time)-callibration.call_S22;
    end;
        end;
        end;
  function GroupDelay(Fcenter,Fspan:Real;Type_of_measurment:SmallInt):Real;
{
var
scale,referecne:Real;
auto:boolean;
}
   begin
{auto:=False;}
       Result:=0;
      if calibration_proc.gd then fspan:=fspan+callibration.cal_GD; //new span
prologix.Write_Data('BW3');// IF 100HZ
{//autoscale new algorithm 
command:='I21;DF1;'FRC '+floatToStr(Fcenter)+' Hz; FRS '+floatToStr(Fspan)+' Hz;MTX';
prologix.Write_Data(command);
Marke1:=prologix.read_data(sleep_time)
command:='I21;DF1;'FRC '+floatToStr(Fcenter)+' Hz; FRS '+floatToStr(Fspan)+' Hz;MKP 200;DM1';
prologix.Write_Data(command);
marker2:=prologix.read_data(sleep_time);
autoscale(marker1,marker2,scale,reference);
command:='DIV '+floatToStr(scale)+' DBR;REF 'floatToStr(reference)+' DBR';
prologix.Write_Data(command);

}
{if not autoscale then } //prepare the machine
       command:='I21;DF7;ASL;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+' Hz';
        prologix.Write_Data(command);
       //end;
      case Type_of_measurment of
      15://max group delay
       begin
       command:='MTX;DM1';
        end;
      7://group delay in a BW ref min
       begin
        command:='MTN;ZMK;MTX;DM1';
        end;
      14://group delay variation
       begin
        command:='MTX;ZMK;MTN;DM1';
        end;
      17://Group delay in BW ref CF
       begin
        command:='MKP 200;ZMK;MTX;DM1';
        end;
      18://Absolute Group Delay
       begin
        command:='MTX;DM1';

        end;
      end;

       prologix.Write_Data(command);
        Result:=prologix.read_data(sleep_time);
 prologix.Write_Data('BW4');// IF=1KHz
      end;


      function Ripple(Fcenter,Fspan:Real):Real;
       begin
      command:='I21;DF7;DIV 1 DBR;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan*0.8)+' Hz;MTX;ZMK;MTN;DM1';
      prologix.Write_Data(command);
      Result:=prologix.read_data(sleep_time);
          end;
 function center_frequnency_x_db(fcenter,fspan,x:Real):Real;
 var
 temp_left,temp_Right,scale:Real;
   begin
       if Abs(x)>5 then scale:=2 else scale:=1;
   temp_left:=0;temp_right:=0;
  command:='I21;DF7;DIV '+floattoStr(scale)+' DBR; FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+'Hz;MTX;ZMK;MTV '+FloatToStr(x)+' DBR;MRT;MP1';
  prologix.Write_Data(command);
  temp_Left:=prologix.read_data(sleep_time);
  command:='I21;DF7;DIV '+floatToStr(scale)+' DBR;FRC '+FloatToStr(fcenter)+' Hz; FRS '+FloatToStr(fspan)+'Hz;MTX;ZMK;MTV '+floatToStr(x)+' DBR;MLT;MP1';
  prologix.Write_Data(command);
  temp_Right:=prologix.read_data(sleep_time);
  Result:=(temp_right-temp_left)/2;
  end;
 function bandwidth_x_db(fcenter,fspan,x:Real):Real;
 var
  command:string;change:Boolean;
  temp_left,temp_Right:Real;
   begin
   change:=False;
if x>60 then begin change:=True; prologix.Write_Data('BW3') end else prologix.Write_Data('BW1');
   command:='I21;DF7;DIV 1 DBR;FRC '+FloatToStr(fcenter)+'Hz; FRS '+FloatToStr(fspan)+'Hz;MTX;ZMK;MTV '+FloatToStr(x)+' DBR;MRT;MP1';
  prologix.Write_Data(command);
  temp_Left:=prologix.read_data(sleep_time);
  command:='I21;DF7;FRC '+FloatToStr(fcenter)+'Hz; FRS '+FloatToStr(fspan)+'Hz;MTX;ZMK;MTV '+floatToStr(x)+' DBR;MLT;MP1';
  prologix.Write_Data(command);
  temp_Right:=prologix.read_data(sleep_time);
  Result:=(temp_right-temp_left);
  if change then prologix.Write_Data('BW3');
  end;
 function attn_at_Freq(Fcenter,fspan,atten_freq:Real;type_of_measure:smallInt):Real;
 var
  new_span,position,temp:Real;
  outside:boolean;
  begin
  outside:=false;
     Result:=0; new_span:=0;
  if atten_freq>fcenter+fspan then //out of screen high
    begin
      new_span:=atten_freq-fcenter;
      outside:=True;
    end;
    if atten_freq<fcenter-fspan then //out of screen low
  begin
   new_span:=fcenter-atten_freq;
   outside:=True;
  end;
if outside then fspan := new_span;
  position := fspan / 400;
  

  case type_of_measure of
  12://Atten. at freq. (min/max);  relative attenuation
  begin
 prologix.Write_Data('I21;DF7;DIV 10 DBR; FRC ' + FloatToStr(fcenter) + 'Hz; FRS ' + FloatToStr(fspan) + 'Hz;MKP ' + FloatToStr(position) + ';MTX;ZMK;');//make zero at max
  //need rounding
  if frac(position) <> 0 then
begin
   position := ceil(position);
     // interpolattion
prologix.Write_Data('I21;DF7;DIV 10 DBR; FRC ' + FloatToStr(fcenter) + 'Hz; FRS ' + FloatToStr(fspan) + 'Hz;MKP ' + FloatToStr(position) + ';DM1');
temp := prologix.read_data(sleep_time);
prologix.Write_Data('I21;DF7;DIV 10 DBR; FRC ' + FloatToStr(fcenter) + 'Hz; FRS ' + FloatToStr(fspan) + 'Hz;MKP ' + FloatToStr(position-1) + ';DM1');
  Result := (temp+prologix.read_data(sleep_time))/2;
  end
  else //fspan is correct
  begin
prologix.Write_Data('I21;DF7;DIV 10 DBR; FRC ' + FloatToStr(fcenter) + 'Hz; FRS ' + FloatToStr(fspan) + 'Hz;MKP ' + FloatToStr(position) + ';DM1');
Result := prologix.read_data(sleep_time);
end;
     end;
  16://Atten. at freq.+I.L. (min/max) absolute
   begin
   if frac(position) <> 0 then
begin
   position := ceil(position);
     // interpolattion
prologix.Write_Data('I21;DF7;DIV 10 DBR; FRC ' + FloatToStr(fcenter) + 'Hz; FRS ' + FloatToStr(fspan) + 'Hz;MKP ' + FloatToStr(position) + ';DM1');
temp := prologix.read_data(sleep_time);
prologix.Write_Data('I21;DF7;DIV 10 DBR; FRC ' + FloatToStr(fcenter) + 'Hz; FRS ' + FloatToStr(fspan) + 'Hz;MKP ' + FloatToStr(position-1) + ';DM1');
  Result := (temp+prologix.read_data(sleep_time))/2;
  end
  else //fspan is correct
  begin
prologix.Write_Data('I21;DF7;DIV 10 DBR; FRC ' + FloatToStr(fcenter) + 'Hz; FRS ' + FloatToStr(fspan) + 'Hz;MKP ' + FloatToStr(position) + ';DM1');
Result := prologix.read_data(sleep_time);
   end;

   end;
  4://Attenuation at stopband search min
   begin
   prologix.Write_Data('I21;DF7;DIV 10 DBR; FRC ' + FloatToStr(fcenter) + 'Hz; FRS ' + FloatToStr(fspan) + 'Hz;MKP ' + FloatToStr(position) + ';DM1');
  end;
  end;


        end;
 function Attenuation_at_stopband(Fcenter,Fspan,low_freq,High_freq,x:Real;left_or_right:smallInt):Real;
 var
 left_limit,right_limit,span,scale:Real;
 change:Boolean;
 begin
 change:=False;
 left_Limit:=Fcenter-Low_freq;  span:=0;
 Right_Limit:=Fcenter+High_freq;
 Span:=Right_Limit-left_limit; //use this span for the measurment.
 if abs(x)>10 then scale:=10 else scale:=5;
if x>60 then begin change:=True; prologix.Write_Data('BW3');end else begin change:=False; prologix.Write_Data('BW4');end;
 command:='I21;DF7;DIV '+FloatToStr(scale)+' DBR; FRC ' + FloatToStr(fcenter) + ' Hz; FRS ' + FloatToStr(fspan) + ' Hz;MKP 200;MTX;ZMK';
  prologix.Write_Data(command);
  case left_or_right of
  4: begin
  command:='MKP 0;DM1';
  end;
  5:begin
  command:='MKP 400;DM1';
  end;
  end;
   prologix.Write_Data(command);
   Result:= prologix.read_data(sleep_time);
   if change then prologix.Write_Data('BW4');//restore IF=1KHz
   end;
 function bandwidth(Fcenter,Fspan,x:Real;type_or_measurement:smallInt):Real;
 var
 scale,ref:Real;
  begin
   ref:=0;
   Result:=0;
  scale:=find_scale(fcenter,fspan);
  if  scale> 5 then ref:=scale-1;
if x>60 then prologix.Write_Data('BW3') else prologix.Write_Data('BW1');
 case type_or_measurement of
//  bandwith 0-xdf from cf
  19:begin
  command:='I21;DF7;DIV 1 DBR; REF' +FloatToStr(ref)+' DBR; FRC ' + FloatToStr(fcenter) + ' Hz; FRS ' + FloatToStr(fspan) + ' Hz;MP1 200;ZMK;MTV '+FloatToStr(x)+' DBR;MRT;DM1';//search Right
  prologix.Write_Data(command);
  scale:=prologix.read_data(sleep_time);
  command:='MLT'; //search Left
  prologix.Write_Data(command);
  ref:=prologix.read_data(sleep_time);
  Result:=scale+ref;
  end;
   //bandwith -xdb and   total bandwith

  8,9,13:begin

    command:='I21;DF7;DIV 1 DBR; REF ' +FloatToStr(ref)+' DBR; FRC ' + FloatToStr(fcenter) + ' Hz; FRS ' + FloatToStr(fspan) + ' Hz;MTX;ZMK;MTV '+FloatToStr(x)+' DBR;MRT;DM1';//search Right
  prologix.Write_Data(command);
  scale:=prologix.read_data(sleep_time);
  command:='MLT'; //search Left
  prologix.Write_Data(command);
  ref:=prologix.read_data(sleep_time);
  Result:=scale+Ref;
  end;
  end;
end;
function spurious_ultimate( Fcenter,zero_span,stop_span:real):Real;
begin
if zero_span<=0 then zero_span:=stop_span/2;
command:='I21;DF7;DIV 2 DBR;BW3;FRC ' + FloatToStr(fcenter) + ' Hz; FRS ' + FloatToStr(zero_span) + ' Hz;MTX;ZMKT';//find center frequency max
prologix.Write_Data(command);
command:='I21;DF7;DIV 2 DBR;BW3; FRC ' + FloatToStr(fcenter) + ' Hz; FRS ' + FloatToStr(stop_span) + ' Hz;MTX;DM1';//find at stopband spurious/ulimate max
prologix.Write_Data(command);
Result:=prologix.read_data(sleep_time);
prologix.Write_Data('BW4');
end;

function Next125(x: Double): Double;
var
  exp10, f, base: Double;
const
  Epsilon = 1e-9;
begin
  if x <= 0 then Exit(100.0e-12);

  exp10 := Power(10, Floor(Log10(x)));
  f := x / exp10;

  if f <= (1.0 + Epsilon) then base := 1.0
  else if f <= (2.0 + Epsilon) then base := 2.0
  else if f <= (5.0 + Epsilon) then base := 5.0
  else base := 10.0;

  Result := base * exp10;

  if Result < 100.0e-12 then Result := 100.0e-12;
  if Result > 100.0 then Result := 100.0;
end;
     procedure Marker_AutoScale(Marker1Value, Marker2Value: Double;
  out Scale, Reference: Double);
var
  MinValue, MaxValue : Double;
  Range              : Double;
  TargetCenter       : Double;
  Step               : Double;
begin

  MinValue := Min(Marker1Value, Marker2Value);
  MaxValue := Max(Marker1Value, Marker2Value);
  Range := MaxValue - MinValue;

  if Range = 0 then Range := 1.0e-9;

  Scale := Next125(Range / 10.0);

  TargetCenter := (MinValue + MaxValue) / 2.0;

  Step := Scale / 10.0;
  Reference := Round(TargetCenter / Step) * Step;

  if Reference > 1000.0 then Reference := 1000.0;
  if Reference < -1000.0 then Reference := -1000.0;
end;
initialization
 begin
 calibration_proc.S11:=False;
calibration_proc.S22:=False;
calibration_proc.IL:=False;
calibration_proc.GD:=False;
end;


end.
