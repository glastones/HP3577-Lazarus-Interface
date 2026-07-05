unit delete;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  DataBaseModule;

type

  { TfrmDelete }

  TfrmDelete = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    lstFilter: TListBox;

    procedure Button1Click(Sender: TObject);

    procedure FormShow(Sender: TObject);
    procedure lstFilterClick(Sender: TObject);


  private

  public

  end;

var
  frmDelete: TfrmDelete;

implementation

{$R *.lfm}

{ TfrmDelete }


procedure TfrmDelete.FormShow(Sender: TObject);

begin
lstFilter.Clear;
try
lstFilter.Items.Assign(DataModule1.ReadFilters);
 Except
  on E: exception do
  ShowMessage('Error '+E.Message);
  end;


lstfilter.Sorted:=True;
lstFilter.ItemIndex:=-1;
    frmdelete.top:=(Screen.DesktopHeight-frmdelete.Height) div 2;
   frmdelete.left:=(screen.DesktopWidth-frmdelete.Width)div 2;
end;

// FIX (CRITICAL): the deletion used to live in lstFilterClick, so merely
// selecting a filter deleted it. Deletion now happens ONLY on the button,
// after an explicit confirmation, and removes the child rows in
// measurement_params too (so no orphan rows are left behind).
procedure TfrmDelete.Button1Click(Sender: TObject);
var
  selected: String;
begin
  if lstFilter.ItemIndex < 0 then
  begin
    ShowMessage('Select a filter to delete first.');
    Exit;
  end;

  selected := Trim(lstFilter.Items[lstFilter.ItemIndex]);
  if selected.IsEmpty or String.IsNullOrWhiteSpace(selected) then Exit;
  // in case the name is empty in database, restore the stored placeholder
  if selected = '-' then selected := ' -    ';

  if MessageDlg('Confirm Deletion',
       'Delete filter "' + Trim(selected) + '" and ALL of its measurements?' + sLineBreak +
       'This cannot be undone.',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  try
   DataModule1.filter_delete(selected);

  except
    on E: Exception do
    begin
       ShowMessage('Error in Deletion : ' + E.Message);
    end;
  end;
  lstFilter.Items.Delete(lstfilter.ItemIndex);
  modalResult:=mrok;
end;






// FIX (startup crash): delete.lfm binds the list box OnClick to lstFilterClick.
// That method had been removed, so form streaming raised
// EReadError "Invalid value for property" at startup. Restored as a no-op:
// selecting an item must NOT delete it - deletion is only via Button1Click.
procedure TfrmDelete.lstFilterClick(Sender: TObject);
begin
  // selection only - no action
end;

end.

