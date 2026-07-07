program Simply_VNA;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Front_Panel, Information, Filter_parameters, DataBaseModule, show,
  tachartlazaruspkg, Serial, LazSerialPort, prologix, delete, Copy, 
Show_correct, Test, misc_function, hp3577;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TSerials, Serials);
  Application.CreateForm(TDataModule1, DataModule1);
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmInformation, frmInformation);
  Application.CreateForm(TfrmParameters, frmParameters);
  Application.CreateForm(TfrmShow, frmShow);
  Application.CreateForm(TfrmDelete, frmDelete);
  Application.CreateForm(TfrmCopy, frmCopy);
  Application.CreateForm(TfrmShow_correct, frmShow_correct);
  Application.CreateForm(TfrmTest, frmTest);
  Application.Run;
end.

