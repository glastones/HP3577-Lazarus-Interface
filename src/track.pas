unit track;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,prologix,
  Spin;

type

  { TfrmTrack }

  TfrmTrack = class(TForm)
    Start: TButton;
    Stop: TButton;
    chkMax: TCheckBox;
    chkMin: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    spTime: TSpinEdit;
    Timer1: TTimer;
    procedure chkMaxChange(Sender: TObject);
    procedure chkMinChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure spTimeChange(Sender: TObject);
    procedure spTimeEditingDone(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

var
  frmTrack: TfrmTrack;

implementation

{$R *.lfm}

{ TfrmTrack }

procedure TfrmTrack.FormCreate(Sender: TObject);
begin
  spTime.Value:=0;
  timer1.Enabled:=False;

end;

procedure TfrmTrack.spTimeChange(Sender: TObject);
begin
  if spTime.Value>5000 then
  begin
    ShowMessage('Impractial Large time. Make it Logical');
    spTime.Value:=0;
    spTime.SetFocus;
  end;
end;

procedure TfrmTrack.spTimeEditingDone(Sender: TObject);
begin
    if spTime.Value>5000 then
  begin
    ShowMessage('Impractial Large time. Make it Logical');
    spTime.Value:=0;
    spTime.SetFocus;
  end;
end;

procedure TfrmTrack.StartClick(Sender: TObject);
begin
  if (not chkMax.Checked) and (not chkMin.Checked) then
  begin
 ShowMessage('Choose What you need track Max or Min ');
  Exit;
  end;
  if spTime.Value=0 then
  begin
  ShowMessage('Please enter a valid time delay in ms');
  spTime.SetFocus;
  Exit;
  end;
  if not prologix.config then
  if prologix.isopen then
  begin
  prologix.Write_Data('BD0;FM1;DCH');
  prologix.release;
  end
  else begin
    ShowMessage('Instrument Error');
    Exit;
  end;
timer1.Interval:=spTime.Value;
timer1.Enabled:=True;
Stop.SetFocus;
end;

procedure TfrmTrack.StopClick(Sender: TObject);
begin
  timer1.Enabled:=False; //stop the timer
end;

procedure TfrmTrack.Timer1Timer(Sender: TObject);
begin
    if prologix.isopen then
  begin
  if chkMax.Checked then
  prologix.Write_Data('MTX;TKM')
  else if chkMin.Checked then
 prologix.Write_Data('MTN;TKM');
  prologix.release;
  end

end;

procedure TfrmTrack.chkMaxChange(Sender: TObject);
begin
  if chkMax.Checked then chkMin.Checked:=False;

end;

procedure TfrmTrack.chkMinChange(Sender: TObject);
begin
  if chkMin.Checked then chkMax.Checked:=False;

end;

end.

