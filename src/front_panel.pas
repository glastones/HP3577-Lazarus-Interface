unit Front_Panel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus,information,
  Filter_Parameters,show,delete,copy,Show_correct,FileInfo,test,  LazLogger,LazLoggerBase,s2p;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    mnuS2P: TMenuItem;
    mnuShowScreen: TMenuItem;
    mnuExperiment: TMenuItem;
    nmSelect: TMenuItem;
    mnShow: TMenuItem;
    mnDelete: TMenuItem;
    nmCopy: TMenuItem;
    nmuNew: TMenuItem;
    mnuEdit: TMenuItem;
    mnuExit: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure mnuS2PClick(Sender: TObject);
    procedure mnDeleteClick(Sender: TObject);
    procedure mnShowClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuShowScreenClick(Sender: TObject);
    procedure nmCopyClick(Sender: TObject);
    procedure nmSelectClick(Sender: TObject);
    procedure nmuNewClick(Sender: TObject);
  private

  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}



{ TfrmMain }

procedure TfrmMain.nmuNewClick(Sender: TObject);
begin
     if frmInformation.ShowModal=mrOK then //Show the
     begin
     if  frmParameters.ShowModal=mrOK then
     begin

     end;

end;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  FileVerInfo: TFileVersionInfo;

begin
     FileVerInfo:=TFileVersionInfo.Create(nil);
    // show the version in the title bar
      try
        FileVerInfo.FileName:=Application.ExeName;
        FileVerInfo.ReadFileInfo;
        frmMain.Caption := 'Simply VNA  ' + FileVerInfo.VersionStrings.Values['FileVersion'];
      finally
        FileVerInfo.Free;
      end;
    frmMain.top:=(Screen.DesktopHeight-frmMain.Height) div 2;
   frmMain.left:=(screen.DesktopWidth-frmMain.Width)div 2;


  end;

procedure TfrmMain.mnuS2PClick(Sender: TObject);
begin
  if frmS2P.ShowModal=mrOK then //Show the form
     begin

     end;
end;



procedure TfrmMain.mnDeleteClick(Sender: TObject);
begin
   if frmDelete.ShowModal=mrOK then //Show the form
     begin

     end;
end;

procedure TfrmMain.mnShowClick(Sender: TObject);
begin
  if frmShow_correct.ShowModal=mrOk then   //Show the form
    begin

    end;
end;

procedure TfrmMain.mnuExitClick(Sender: TObject);
begin
 Application.terminate;
 Exit;
end;

procedure TfrmMain.mnuShowScreenClick(Sender: TObject);
begin
  frmShow.Show;
end;

procedure TfrmMain.nmCopyClick(Sender: TObject);
begin
if   frmCopy.ShowModal=mrOK then   //Show the form
  begin

  end;
end;

procedure TfrmMain.nmSelectClick(Sender: TObject);
begin

frmTest.showModal;
{if not prologix.config then
  begin
    ShowMessage('Connect with the prologix module in usb');
    exit;
  end;
}
end;

end.

