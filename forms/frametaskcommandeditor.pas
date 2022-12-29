unit frameTaskCommandEditor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, SynEdit,
  SynHighlighterSQL, LCLType, framebase;

type

  { TfrmTaskCommandEditor }

  TfrmTaskCommandEditor = class(TBaseFrame)
    edCommand: TSynEdit;
    SynSQLSyn: TSynSQLSyn;
    procedure edCommandKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  public
    function GetEditorValue(): string; override;
    procedure SetEditorValue(AText: string); override;
    procedure SetFocus; override;
  end;

implementation

{$R *.lfm}

{ TfrmTaskCommandEditor }

procedure TfrmTaskCommandEditor.edCommandKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: Self.Hide();
    VK_RETURN: if ssCtrl in Shift then ApplyChanges();
  end;
end;

function TfrmTaskCommandEditor.GetEditorValue: string;
begin
  Exit(edCommand.Text);
end;

procedure TfrmTaskCommandEditor.SetEditorValue(AText: string);
begin
  edCommand.Text := AText;
end;

procedure TfrmTaskCommandEditor.SetFocus;
begin
  edCommand.SetFocus();
end;

end.

