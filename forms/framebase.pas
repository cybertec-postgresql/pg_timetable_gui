unit framebase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, SynEdit,
  SynHighlighterSQL, ComCtrls, LCLType, Db;

type

  { TBaseFrame }

  TBaseFrame = class(TFrame)
    btnOK: TButton;
    btnCancel: TButton;
    pnlButtons: TPanel;
    procedure btnOKClick(Sender: TObject);
    procedure FrameExit(Sender: TObject);
  protected
    fldCommand: TField;
    function GetEditorValue(): string; virtual; abstract;
    procedure SetEditorValue(AText: string); virtual; abstract;
  public
    procedure ShowEditor(AField: TField; ATopLeft: TPoint);
    procedure HideEditor();
    procedure ApplyChanges();
    procedure CreateParams(var Params: TCreateParams); override;
  end;

implementation

{$R *.lfm}

{ TBaseFrame }

procedure TBaseFrame.FrameExit(Sender: TObject);
begin
  HideEditor();
end;

procedure TBaseFrame.btnOKClick(Sender: TObject);
begin
  ApplyChanges();
end;

procedure TBaseFrame.ShowEditor(AField: TField; ATopLeft: TPoint);
begin
  SetEditorValue(AField.AsString);
  fldCommand := AField;
  Left := ATopLeft.X;
  Top := ATopLeft.Y;
  Show();
  SetFocus();
end;

procedure TBaseFrame.HideEditor;
begin
  Hide();
  Parent.SetFocus();
end;

procedure TBaseFrame.ApplyChanges;
begin
  fldCommand.DataSet.Edit;
  fldCommand.AsString := GetEditorValue();
  HideEditor();
end;

procedure TBaseFrame.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_SIZEBOX;
end;

end.

