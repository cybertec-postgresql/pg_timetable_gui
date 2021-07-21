unit fmConnect;

{$MODE Delphi}

interface

uses
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, DB, PQConnection, SQLDB;

type

  { TfmConnect }

  TfmConnect = class(TForm)
    Bevel1: TBevel;
    btnTest: TButton;
    laUser: TLabel;
    laPass: TLabel;
    DBUserID: TEdit;
    DBPasswd: TEdit;
    laDbName: TLabel;
    DBName: TEdit;
    laHost: TLabel;
    DBHost: TEdit;
    laPort: TLabel;
    DBPort: TEdit;
    OkBtn: TButton;
    CancelBtn: TButton;
    Panel1: TPanel;
  private
    Database: TPQConnection;
    function Edit: Boolean;
  public
    procedure GetDatabaseProperty(Db: TPQConnection);
    procedure SetDatabaseProperty(Db: TPQConnection);
  end;

function EditDatabase(ADatabase: TPQConnection): Boolean;

var
  fmConnect: TfmConnect;

implementation

{$R *.lfm}

function EditDatabase(ADatabase: TPQConnection): Boolean;
begin
  with TfmConnect.Create(Application) do
  try
    Database := ADatabase;
    Result := Edit;
  finally
    Free;
  end;
end;

function TfmConnect.Edit: Boolean;
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
  DBName.Text := DB.DatabaseName;
  DBUserId.Text := db.UserName;
  DBPasswd.Text := db.Password;
  DBHost.Text := Db.HostName;
  DBPort.Text := Db.Params.Values['port'];
  if DBPort.Text = '' then DBPort.Text := '5432';
end;

procedure TfmConnect.SetDatabaseProperty(Db: TPQConnection);
begin
  DB.DatabaseName := DBName.Text;
  db.UserName := DBUserId.Text;
  db.Password := DBPasswd.Text;
  Db.HostName := DBHost.Text;
  Db.Params.Add(Format('port=%d', [StrToIntDef(DBPort.Text, 5432)]));
end;

end.


