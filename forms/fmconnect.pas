unit fmConnect;

{$MODE Delphi}

interface

uses
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, EditBtn, DB, PQConnection, SQLDB;

type

  { TfmConnect }

  TfmConnect = class(TForm)
    Bevel1: TBevel;
    btnTest: TButton;
    edPasswd: TEditButton;
    laUser: TLabel;
    laPass: TLabel;
    edUserID: TEdit;
    laDbName: TLabel;
    edDatabase: TEdit;
    laHost: TLabel;
    edHost: TEdit;
    laPort: TLabel;
    edPort: TEdit;
    btnOk: TButton;
    btnCancel: TButton;
    pnlHeader: TPanel;
    procedure edPasswdButtonClick(Sender: TObject);
  private
    Database: TPQConnection;
    function Edit: boolean;
  public
    procedure GetDatabaseProperty(Db: TPQConnection);
    procedure SetDatabaseProperty(Db: TPQConnection);
  end;

function EditDatabase(ADatabase: TPQConnection): boolean;

var
  fmConnect: TfmConnect;

implementation

{$R *.lfm}

function EditDatabase(ADatabase: TPQConnection): boolean;
begin
  with TfmConnect.Create(Application) do
    try
      Database := ADatabase;
      Result := Edit;
    finally
      Free;
    end;
end;

procedure TfmConnect.edPasswdButtonClick(Sender: TObject);
begin
  with (Sender as TEditButton) do
    if EchoMode = emNormal then
      EchoMode := emPassword
    else
      EchoMode := emNormal;
end;

function TfmConnect.Edit: boolean;
begin
  GetDatabaseProperty(Database);
  Result := False;
  if ShowModal() = mrOk then
  begin
    SetDatabaseProperty(Database);
    Result := True;
  end;
end;

procedure TfmConnect.GetDatabaseProperty(Db: TPQConnection);
begin
  edDatabase.Text := DB.DatabaseName;
  edUserID.Text := DB.UserName;
  edPasswd.Text := DB.Password;
  edHost.Text := DB.HostName;
  edPort.Text := DB.Params.Values['port'];
  if edPort.Text = '' then
    edPort.Text := '5432';
end;

procedure TfmConnect.SetDatabaseProperty(Db: TPQConnection);
begin
  DB.DatabaseName := edDatabase.Text;
  DB.UserName := edUserID.Text;
  DB.Password := edPasswd.Text;
  DB.HostName := edHost.Text;
  DB.Params.Add(Format('port=%d', [StrToIntDef(edPort.Text, 5432)]));
end;

end.

