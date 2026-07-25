unit Copy;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MaskEdit,
  Buttons, SynEdit, DataBaseModule;

type

  { TfrmCopy }

  TfrmCopy = class(TForm)
    btnCopy: TButton;
    Label1: TLabel;
    lstFilters: TListBox;
    mskFilterName: TMaskEdit;

    procedure btnCopyClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lstFiltersClick(Sender: TObject);

    procedure mskFilterNameKeyPress(Sender: TObject; var Key: char);
  private

  public

  end;

var
  frmCopy: TfrmCopy;

implementation

{$R *.lfm}

{ TfrmCopy }

procedure TfrmCopy.FormCreate(Sender: TObject);
begin
   self.top:=(Screen.DesktopHeight-self.Height) div 2;
   self.left:=(screen.DesktopWidth-self.Width)div 2;
   end;

procedure TfrmCopy.btnCopyClick(Sender: TObject);
var
  selected:String;

begin
selected:='';
//if not filter selected
if lstFilters.ItemIndex<=-1 then begin ShowMessage('First Choose a Filter need to be copied'); exit; end;
// FIX: never copy without a valid destination name. Without this guard,
  // pressing Copy with an untouched name field created a junk filter named '-'.
  if (Trim(mskFilterName.Text) = '') or (Trim(mskFilterName.Text) = '-') then
  begin
    ShowMessage('Enter a name for the new filter.');
    mskFilterName.SetFocus;
    Exit;
  end;

//if filter selected
if lstFilters.ItemIndex> -1 then
 begin
  //read the name
  selected:=trim(lstFilters.Items[lstFilters.ItemIndex]);
  //if is empty or null
  if selected.IsEmpty or String.IsNullOrWhiteSpace(selected) then Exit;
  //if is - special chartacter
  if trim(selected)='-' then begin ShowMessage('Enter Filter Name');Exit; end;
  if lstfilters.Items.IndexOf(trim(mskFilterName.Text))<>-1 then
  begin
   Showmessage('This filter name already Exists. Try Again');
   mskFilterName.Text:='';
   mskFilterName.SetFocus;
   selected:='';
   Exit;
  end;
  end;
    try
  if DataModule1.CopyFilter(Trim(selected),Trim(mskFilterName.Text)) then
  begin
   ShowMessage('Copy Successful');
    ModalResult := mrOK;
  end;
  Except
    on E: Exception do begin
    ShowMessage(E.Message);
    ModalResult:=mrRetry;
  end;
  end;

 end;

procedure TfrmCopy.FormActivate(Sender: TObject);
var
  fl: TStringList;
begin
 lstFilters.Clear;
    frmCopy.top:=(Screen.DesktopHeight-frmCopy.Height) div 2;
   frmCopy.left:=(screen.DesktopWidth-frmCopy.Width)div 2;
   // FIX (leak): ReadFilters returns a freshly created TStringList. Assign copies
   // its contents, but the returned object must be freed or it leaks every time
   // this form opens.
   fl := DataModule1.ReadFilters;
   try
     lstFilters.Items.Assign(fl);
   finally
     fl.Free;
   end;
   lstFilters.Sorted:=True;
end;



procedure TfrmCopy.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin

//only 1 used
 DataModule1.release(False);
 CloseAction:=CloseAction;
end;




procedure TfrmCopy.lstFiltersClick(Sender: TObject);

begin
mskFilterName.Clear;
mskFilterName.SetFocus;

end;


procedure TfrmCopy.mskFilterNameKeyPress(Sender: TObject; var Key: char);
begin
  //Lock the first letter
  //M for matching
  //F for Filter or Final
  //T for Test
  //R for Revision
    if key=#8 then exit;
   case mskFilterNAme.SelStart of
   0: if not (Key in ['M','F','T','R','m','f','t','r'] )then
  key:=#0;

  2..5: begin
    if not (Key in ['0'..'9']) then
      Key := #0; //Only numbers here
  end

  // anything else #0
  else
    Key := #0;
end;
end;




end.
