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
    call_S12:Real;
    cal_GD:Real;
    cal_scale:real;//reference
     end;
calibration_process=Record
IL:Boolean;
S11:Boolean;
S22:Boolean;
S12:Boolean;
GD:boolean;
end;
bandwidth_Limits=record
Left:Real;
Right:Real;
end;

restore_values=Record
center:Real;
span:real;
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
    procedure restore_view(Fcenter,fspan:Real);
    function bandwidth_minus_plus(Fcenter,Fspan,x:Real;type_or_measurement:smallInt):Bandwidth_Limits;

                  const sleep_time=25;  //no more than 800ms no less 200
                  const Scale_limit=2; //More than limit activate the reference for scale.
                  const IL_Normal=4;
                  const IL_NO_50=10;
                var

             callibration:Calibrate_variables;
             calibration_proc:Calibration_process;
             restore:Restore_values;
             IS_50:Boolean;

            implementation
            uses test;
 var

             command:String;

 function calibrate(fcenter,fspan:real;measurement:SmallInt):Calibrate_variables;
var
          step,temp:real; cal:boolean;

begin
  IS_50:=False;
  cal:=False;
  prologix.Write_Data('IPR;BD0;FM1;DCH');//Reset and initialize as fast as possible.
  if frmTest.cbAtten.checked then prologix.Write_Data('AB2') else prologix.Write_Data('AB1');//to be checked.
  case measurement of
1: //S21
begin
if not calibration_proc.IL then 
begin
if MessageDlg('Calibration Routine','Please Install the short',mtwarning,[mbYes],0)=mrYes then
begin
       while not cal do
      begin
       prologix.Write_Data('MO0');// remove Zero Marking for the new measurement
       command:='FRS '+FloatToStr(fspan)+' Hz';
         prologix.Write_Data(command);
         command:='I21;DF7;FRC '+FloatToStr(fcenter)+' Hz';
         prologix.Write_Data(command);
         command:='DIV 1 DBR;MTN;TKM;DM1';
         prologix.Write_Data(command);
         Result.call_S21:=prologix.read_data(sleep_time);
         if (Result.call_S21<>0) and (Abs(Result.call_S21)<IL_NO_50) then begin cal:=True; calibration_proc.IL:=True; end
         else
         begin
         cal:=False;
         calibration_proc.IL:=False;
         ShowMessage('Short is not Installed');
         end;
          end;
       end
end; end;

2: //GD
begin
if not calibration_proc.GD then
  begin
  step:=fspan/400;//calculate step
  step:=step*10;//10 step distance
  command:='I21;DF1;AP4;BW3;MO0;NS7';
  prologix.Write_Data(command);
   command:='FRS '+FloatToStr(fspan)+' Hz';
  prologix.Write_Data(command);
  command:='FRC '+FloatToStr(fcenter)+' Hz';
  prologix.Write_Data(command);
  command:='MKP 10;TKM;MP1'; //loose 10 steps
  prologix.Write_Data(command);
  temp:=prologix.read_data(sleep_time);
  command:='I21;DF1;AP4;BW3';
  prologix.Write_Data(command);
  command:='FRC '+FloatToStr(fcenter)+' Hz';
  prologix.Write_Data(command);
  command:='FRS '+FloatToStr(fspan)+' Hz';
  prologix.Write_Data(command);
  command:='MKP 390;TKM;MP1';  //loose 10 steps
  prologix.Write_Data(command);
  Result.cal_GD:=fspan-(prologix.read_data(sleep_time)-temp);
       calibration_proc.GD:=True;
       command:='BW4';//return IF=1KHz
       prologix.Write_Data(command);
  end;
end;
3:  //I22-I11
begin
if not calibration_proc.S11 then
  begin
if MessageDlg('Calibration Routine','Leave the port open',mtwarning,[mbYes, mbNo],0)=mrYes then
begin
prologix.Write_Data('MO0');// remove Zero Marking for the new measurement
  command:='I22;DF7';
  prologix.Write_Data(command);
  command:='FRS '+FloatToStr(fspan)+' Hz';
  prologix.Write_Data(command);
  command:='FRC '+FloatToStr(fcenter)+' Hz';
  prologix.Write_Data(command);
  command:='MTN;TKM;DM1';
   prologix.Write_Data(command);
   Result.call_S22:=prologix.read_data(sleep_time);
   command:='I11;DF7';
    prologix.Write_Data('MO0');// remove Zero Marking for the new measurement
   prologix.Write_Data(command);
    command:='FRS '+FloatToStr(fspan)+' Hz';
   prologix.Write_Data(command);
   command:='FRC '+FloatToStr(fcenter)+' Hz';
   prologix.Write_Data(command);
   command:='MTN;TKM;DM1';
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
4:begin  //12
if not calibration_proc.S12 then
   prologix.Write_Data('MO0');// remove Zero Marking for the new measurement
       command:='I12;DF7;FRS '+FloatToStr(fspan)+' Hz';
         prologix.Write_Data(command);
         command:='FRC '+FloatToStr(fcenter)+' Hz';
         prologix.Write_Data(command);
         command:='DIV 1 DBR;MTN;TKM;DM1';
         prologix.Write_Data(command);
         Result.call_S12:=prologix.read_data(sleep_time);
         if (Result.call_S21<>0) and (Abs(Result.call_S21)<IL_NO_50) then begin cal:=True; calibration_proc.S12:=True; end
         else
         begin
         cal:=False;
         calibration_proc.S12:=False;
         end;
  end;

end;

 end;




 function find_scale(fcenter,fspan:Real):Real; //find the scale and make it reference.
 var
             temp:real;
 begin

       temp:=0;
       command:='I21;DF7;DIV 1 DBR';
       prologix.Write_Data(command);
       command:='FRS '+FloatToStr(fspan)+' Hz';
       prologix.Write_Data(command);
       command:='FRC '+FloatToStr(fcenter)+' Hz';
       prologix.Write_Data(command);
       command:='MTX;MO0;TKM;DM1';
       prologix.Write_Data(command);
       temp:=prologix.read_data(sleep_time);
       Result:=(-1)*(Abs(temp)-Scale_Limit);
 end;

function IL(fcenter,fspan:Real;types:smallInt):Real; //1 IL 2 IL from center
 var
             temp:Real;
begin
               Result:=0;
               if Abs(callibration.cal_scale)>Scale_Limit then begin
               command:='REF '+FloatToStr(callibration.cal_scale)+' DBR';
               command:=StringReplace(command,',','.',[rfReplaceAll]);
               prologix.Write_Data(command);
               end;
               command:='I21;DF7;DIV 1 DBR';
               prologix.Write_Data(command);
               command:='FRS '+FloatToStr(fspan)+' Hz';
               prologix.Write_Data(command);
               command:='FRC '+FloatToStr(fcenter)+' Hz';
               prologix.Write_Data(command);

               case types of
0:     command:='MTX;TKM;DM1';
1:    command:='MKP 200;TKM;DM1';
end;
       prologix.Write_Data(command);
      temp:=Abs(prologix.read_data(sleep_time));
      Result:=temp-Abs(callibration.call_S21);
      if not IS_50 then Result:=Result-Abs(callibration.call_S21)-Abs(callibration.cal_scale);//if it's not 50ohm remove reference
      if Result<=0.01 then Result:=0;
      Result:=Result*(-1);
      end;
  function RL(fcenter,fspan:Real;input:smallInt):Real; //10=S11 11=S22
   begin
       Result:=0;
case input of
      10://s11
        begin
    command:='I11;DF7;DIV 5 DBR';
    prologix.Write_Data(command);
    command:='FRS '+FloatToStr(fspan)+' Hz';
    prologix.Write_Data(command);
    command:='FRC '+FloatToStr(fcenter)+' Hz';
    prologix.Write_Data(command);
    command:='MTX;TKM;MP1';
    prologix.Write_Data(command);
   Result:=prologix.read_data(sleep_time)-callibration.call_S11;
    end;
      11://s22
        begin
    command:='I22;DF7;DIV 5 DBR';
    prologix.Write_Data(command);
   command:='FRS '+FloatToStr(fspan)+' Hz';
   prologix.Write_Data(command);
   command:='FRC '+FloatToStr(fcenter)+' Hz';
   prologix.Write_Data(command);
    command:='MTX;TKM;MP1';
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
       command:='I21;DF7;ASL';
       command:='FRS '+FloatToStr(fspan)+' Hz';
       prologix.Write_Data(command);
       command:='FRC '+FloatToStr(fcenter)+' Hz';
       prologix.Write_Data(command);
       //end;
      case Type_of_measurment of
      15://max group delay
       begin
       command:='MTX;TKM;DM1';
        end;
      7://group delay in a BW ref min
       begin
       command:='MTN;ZMK;MTX;TKM;DM1';
        end;
      14://group delay variation
       begin
       command:='MTX;ZMK;MTN;TKM;DM1';
        end;
      17://Group delay in BW ref CF
       begin
       command:='MKP 200;ZMK;MTX;TKM;DM1';
        end;
      18://Absolute Group Delay
       begin
        command:='MTX;TKM;DM1';
       end;
      end;

       prologix.Write_Data(command);
        Result:=prologix.read_data(sleep_time);
 prologix.Write_Data('BW4;DF7');// IF=1KHz
 if Type_of_measurment in [7,14,17] then
 prologix.Write_Data('MO0');// remove Zero Marking for the new measurement
      end;

       function Ripple(Fcenter,Fspan:Real):Real;
       begin

          Result:=0;
          if  not IS_50 or (Abs(callibration.cal_scale)>IL_NO_50) then begin
               command:='REF '+FloatToStr(callibration.cal_scale)+' DBR';
               command:=StringReplace(command,',','.',[rfReplaceAll]);
               prologix.Write_Data(command);
               end;
          command:='I21;DF7;DIV 1 DBR';
         prologix.Write_Data(command);
         command:='FRS '+FloatToStr(fspan*0.8)+' Hz';
         prologix.Write_Data(command);
         command:='FRC '+FloatToStr(fcenter)+' Hz';
         prologix.Write_Data(command);
         command:='MTX;ZMK;MTN;TKM;DM1';
         prologix.Write_Data(command);
         Result:=prologix.read_data(sleep_time);
         prologix.Write_Data('MO0');//Remove Zero Marking
       end;


 function center_frequnency_x_db(fcenter,fspan,x:Real):Real;
 var
 temp_left,temp_Right,scale,ref:Real;
   begin
      ref:=0;Result:=0;temp_left:=0;temp_right:=0;
       if Abs(x)>5 then begin scale:=2; ref:=Abs(x)-scale; ref:=ref*(-1);  end else  scale:=1;
        command:='I21;DF7;DIV '+floattoStr(scale)+' DBR';
        prologix.Write_Data(command);
        command:='REF '+FloatToStr(ref)+' DBR';
        prologix.Write_Data(command);
        command:='FRS '+FloatToStr(fspan)+' Hz';
        prologix.Write_Data(command);
        command:='FRC '+FloatToStr(fcenter)+' Hz';
        prologix.Write_Data(command);
        command:='MRT;TKM;MP1';
        prologix.Write_Data(command);
        temp_Left:=Abs(prologix.read_data(sleep_time));
        command:='MLT;TKM;MP1';
        prologix.Write_Data(command);
        temp_Right:=Abs(prologix.read_data(sleep_time));
        Result:=(temp_right-temp_left)/2;
 end;
 function bandwidth_x_db(fcenter,fspan,x:Real):Real;
 var
  command:string;change:Boolean;
  temp_left,temp_Right,scale,ref:Real;
   begin
   change:=False;scale:=1;ref:=0;
if Abs(x)>10 then begin
change:=True;
prologix.Write_Data('BW3'); //Lower IF
scale:=10;
ref:=Abs(x)-scale;
ref:=ref*(-1);
end
else prologix.Write_Data('BW4');//Restore IF
  command:='I21;DF7;DIV '+FloatToStr(scale)+' DBR';
  prologix.Write_Data(command);
  command:='REF '+FloatToStr(ref)+' DBR';
  prologix.Write_Data(command);
  command:='FRS '+FloatToStr(fspan)+' Hz';
  prologix.Write_Data(command);
  command:='FRC '+FloatToStr(fcenter)+' Hz';
  prologix.Write_Data(command);
  command:='MTX;ZMK';
  prologix.Write_Data(command);
  command:='MTV '+FloatToStr(x)+' DBR';
  prologix.Write_Data(command);
  command:='MRT;TKM;MP1';
  prologix.Write_Data(command);
  temp_Left:=prologix.read_data(sleep_time);
  command:='MLT;TKM;MP1';
  prologix.Write_Data(command);
  temp_Right:=prologix.read_data(sleep_time);
  Result:=(temp_right-temp_left);
  if change then prologix.Write_Data('BW4');//restore IF
  prologix.Write_Data('MO0');//Remove Zero Marking
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
 prologix.Write_Data('I21;DF7;DIV 10 DBR');
 prologix.Write_Data('FRS ' + FloatToStr(fspan) + ' Hz');
 prologix.Write_Data('FRC ' + FloatToStr(fcenter) + ' Hz');
 prologix.Write_Data('MKP ' + FloatToStr(position) + ';MTX;ZMK;');//make zero at max
  //need rounding
  if frac(position) <> 0 then
begin
prologix.Write_Data('I21;DF7;DIV 10 DBR');
prologix.Write_Data('FRS ' + FloatToStr(fspan) + ' Hz');
prologix.Write_Data ('FRC ' + FloatToStr(fcenter) + ' Hz');
position := ceil(position);
     // interpolattion
prologix.Write_Data('MKP ' + FloatToStr(position) + ';TKM;DM1');
temp := Abs(prologix.read_data(sleep_time));
prologix.Write_Data('MKP ' + FloatToStr(position-1) + ';TKM;DM1');
Result := (temp+Abs(prologix.read_data(sleep_time)))/2;
  end
  else //fspan is correct
  begin
prologix.Write_Data('I21;DF7;DIV 10 DBR');
prologix.Write_Data('FRS ' + FloatToStr(fspan) + ' Hz');
prologix.Write_Data('FRC ' + FloatToStr(fcenter) + ' Hz');
prologix.Write_Data('MKP ' + FloatToStr(position) + ';TKM;DM1');
Result := prologix.read_data(sleep_time);
end;
     end;
  16://Atten. at freq.+I.L. (min/max) absolute
   begin
   if frac(position) <> 0 then
begin
prologix.Write_Data('I21;DF7;DIV 10 DBR');
prologix.Write_Data('FRS ' + FloatToStr(fspan) + ' Hz');
prologix.Write_Data('FRC ' + FloatToStr(fcenter) + ' Hz');
prologix.Write_Data('MKP ' + FloatToStr(position) + ';TKM;DM1');
   position := ceil(position);
     // interpolattion
temp := prologix.read_data(sleep_time);
prologix.Write_Data('MKP ' + FloatToStr(position-1) + ';TKM;DM1');
Result := (temp+prologix.read_data(sleep_time))/2;
  end
  else //fspan is correct
  begin
prologix.Write_Data('I21;DF7;DIV 10 DBR');
prologix.Write_Data('FRS ' + FloatToStr(fspan) + ' Hz');
prologix.Write_Data('FRC ' + FloatToStr(fcenter) + ' Hz');
prologix.Write_Data('MKP ' + FloatToStr(position) + ';TKM;DM1');
Result := prologix.read_data(sleep_time);
   end;
   end;
  4://Attenuation at stopband search min
   begin
   prologix.Write_Data('I21;DF7;DIV 10 DBR');
   prologix.Write_Data('FRS ' + FloatToStr(fspan) + ' Hz');
   prologix.Write_Data('FRC ' + FloatToStr(fcenter) + ' Hz');
   prologix.Write_Data('MKP ' + FloatToStr(position) + ';TKM;DM1');
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
 Right_Limit:=High_freq-Fcenter;
 Span:=Right_Limit+left_limit; //use this span for the measurment.
 if abs(x)>10 then scale:=10 else scale:=5;
if x>60 then begin
change:=True;
prologix.Write_Data('BW3');//Lower IF
end
else
begin
change:=False;
prologix.Write_Data('BW4');//Restore IF
end;
command:='I21;DF7;DIV '+FloatToStr(scale)+' DBR';
prologix.Write_Data(command);
command:='FRS ' + FloatToStr(span) + ' Hz';
 prologix.Write_Data(command);
command:='FRC ' + FloatToStr(fcenter) + ' Hz';
prologix.Write_Data(command);
 command:='MTX;ZMK';
  prologix.Write_Data(command);
 // sleep(sleep_time);
  case left_or_right of
  4: command:='MKP 0;TKM;DM1';
  5: command:='MKP 400;TKM;DM1';
  end;
   prologix.Write_Data(command);
//   sleep(sleep_time);
   Result:= prologix.read_data(sleep_time);
   if change then begin prologix.Write_Data('BW4');
   prologix.Write_Data('MO0');//remove zero marker
   end;//restore IF=1KHz
   end;
 function bandwidth(Fcenter,Fspan,x:Real;type_or_measurement:smallInt):Real;
 var
 scale,temp:Real;
  begin

   Result:=0;
    if Abs(callibration.cal_scale)>Scale_Limit then begin
                  command:='REF '+FloatToStr(callibration.cal_scale)+' DBR';
                  //command:=StringReplace(command,',','.',[rfReplaceAll]);
                  prologix.Write_Data(command);
                  end;
if x>60 then prologix.Write_Data('BW3') else prologix.Write_Data('BW4');
 case type_or_measurement of
//  bandwith 0-xdf from cf

   //bandwith -xdb and   total bandwith

  9,13:begin //8

    command:='I21;DF7;DIV 1 DBR';
    prologix.Write_Data(command);
    command:='FRS ' + FloatToStr(fspan) + ' Hz';
    prologix.Write_Data(command);
    command:='FRC ' + FloatToStr(fcenter) + ' Hz';
    prologix.Write_Data(command);
    command:='MTX;ZMK;MTV '+FloatToStr(x)+' DBR;MRT;TKM;MP1';//search Right
    prologix.Write_Data(command);
  scale:=prologix.read_data(sleep_time);
  command:='MLT;MP1'; //search Left
  prologix.Write_Data(command);
  //sleep(sleep_time);
  temp:=prologix.read_data(sleep_time);
  command:='MO0'; //search Left
 prologix.Write_Data(command);
  Result:=Abs(scale)+Abs(Temp);
  end;
  end;
end;
 function bandwidth_minus_plus(Fcenter,Fspan,x:Real;type_or_measurement:smallInt):Bandwidth_Limits;

 begin
 Result.Right:=0; Result.Left:=0;
 if abs(callibration.cal_scale)>scale_limit then begin
   command:='MO0';
   prologix.Write_Data(command); //remove zero marker for sure
   command:='REF '+FloatToStr(callibration.cal_scale)+' DBR';
   command:=StringReplace(command,',','.',[rfReplaceAll]);
     prologix.Write_Data(command);
     end;
      command:='I21;DF7;DIV 1 DBR';
    prologix.Write_Data(command);
    command:='FRS ' + FloatToStr(fspan) + ' Hz';
    prologix.Write_Data(command);
    command:='FRC ' + FloatToStr(fcenter) + ' Hz';
    prologix.Write_Data(command);

 case type_or_measurement of
  8:begin
    command:='MTV '+FloatToStr(x)+' DBR';//marker max,marker zero,search for -x db
    prologix.Write_Data(command);
    command:='TKM;MTX;ZMK';
    prologix.Write_Data(command);
    command:='MRT;TKM;MP1';//search Right
    prologix.Write_Data(command);
    Result.Right:=Abs(prologix.read_data(sleep_time));//remove sign
    command:='MLT;TKM;MP1'; //search Left;
    prologix.Write_Data(command);
    Result.Left:=Abs(prologix.read_data(sleep_time));//remove sign
   end;
  19:  begin
    command:='MKP 200;ZMK;MTV '+FloatToStr(x)+' DBR';//marker max,marker zero,search for -x db
    prologix.Write_Data(command);
    command:='MRT;TKM;MP1';//search Right
    prologix.Write_Data(command);
    Result.Right:=Abs(prologix.read_data(sleep_time));//remove sign
    command:='MLT;TKM;MP1'; //search Left;
    prologix.Write_Data(command);
    Result.Left:=Abs(prologix.read_data(sleep_time));//remove sign
   end;
 end;

    command:='MO0';//remove zero
    prologix.Write_Data(command);

   end;

 function spurious_ultimate( Fcenter,zero_span,stop_span:real):Real;
begin
if zero_span<=0 then zero_span:=stop_span/2;
command:='I21;DF7;DIV 2 DBR;BW3';
prologix.Write_Data(command);
command:='FRS ' + FloatToStr(Restore.span) + ' Hz';
prologix.Write_Data(command);
command:='FRC ' + FloatToStr(Restore.center) + ' Hz';
prologix.Write_Data(command);
command:='MTX;ZMK';//find center frequency max
prologix.Write_Data(command);
command:='I21;DF7;DIV 10 DBR;BW3';
prologix.Write_Data(command);
command:='FRS ' + FloatToStr(stop_span) + ' Hz';
prologix.Write_Data(command);
command:='FRC ' + FloatToStr(fcenter) + ' Hz';
prologix.Write_Data(command);
command:='MTN;TKM;DM1';//find at stopband spurious/ulimate max
prologix.Write_Data(command);
Result:=prologix.read_data(sleep_time);
prologix.Write_Data('BW4'); //Restore IFBW=1KHz
prologix.Write_Data('MO0');//remove zero marker
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
            procedure restore_view(Fcenter,fspan:Real);
            begin
             command:='FRS '+FloatToStr(Fspan)+' Hz';
             prologix.Write_Data(command);
             command:='FRC '+FloatToStr(Fcenter)+' Hz';
             prologix.Write_Data(command);

             command:='DIV 1 DRB;REF '+FloatToStr(callibration.cal_scale)+' DBR;MKP 200';
             command:=StringReplace(command,',','.',[rfReplaceAll]);
             prologix.Write_Data(command);
             command:='MO0';
             prologix.Write_Data(command);
             //sleep(sleep_time);
             end;


initialization
 begin
calibration_proc.S11:=False;
calibration_proc.S22:=False;
calibration_proc.IL:=False;
calibration_proc.GD:=False;
calibration_proc.S12:=False;
callibration.call_S11:=0;
callibration.call_S22:=0;
callibration.call_S21:=0;
callibration.call_S12:=0;
callibration.cal_GD:=0;
callibration.cal_scale:=0;
restore.center:=0;
restore.span:=0;
end;
   { #todo : implement is is not 50ohm the reference should be active in measurements ,IL , }

end.
