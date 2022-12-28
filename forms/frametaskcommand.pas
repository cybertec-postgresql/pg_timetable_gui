unit frameTaskCommand;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, SynEdit,
  SynHighlighterSQL, LCLType, Db;

type

  { TfrmTaskCommand }

  TfrmTaskCommand = class(TFrame)
    btnOK: TButton;
    btnCancel: TButton;
    edCommand: TSynEdit;
    pnlButtons: TPanel;
    SynSQLSyn: TSynSQLSyn;
    procedure btnOKClick(Sender: TObject);
    procedure edCommandExit(Sender: TObject);
    procedure edCommandKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    fldCommand: TField;
  public
    procedure ShowEditor(AField: TField; ATopLeft: TPoint);
    procedure HideEditor();
    procedure ApplyChanges();
  end;

implementation

{$R *.lfm}

{ TfrmTaskCommand }

procedure TfrmTaskCommand.edCommandExit(Sender: TObject);
begin
  HideEditor();
end;

procedure TfrmTaskCommand.btnOKClick(Sender: TObject);
begin
  ApplyChanges();
end;

procedure TfrmTaskCommand.edCommandKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: Self.Hide();
    VK_RETURN: if ssCtrl in Shift then ApplyChanges();
  end;
end;

procedure TfrmTaskCommand.ShowEditor(AField: TField; ATopLeft: TPoint);
begin
  edCommand.Text := AField.AsString;
  fldCommand := AField;
  Left := ATopLeft.X;
  Top := ATopLeft.Y;
  Show();
  edCommand.SetFocus();
end;

procedure TfrmTaskCommand.HideEditor;
begin
  Hide();
  Parent.SetFocus();
end;

procedure TfrmTaskCommand.ApplyChanges;
begin
  fldCommand.DataSet.Edit;
  fldCommand.AsString := edCommand.Text;
  HideEditor();
end;

end.

