unit uDataModule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, PQConnection, SQLDB;

type

  { TdmPgEngine }

  TdmPgEngine = class(TDataModule)
    dsTasks: TDataSource;
    dsChains: TDataSource;
    PQConn: TPQConnection;
    qryChains: TSQLQuery;
    qryTasks: TSQLQuery;
    transChains: TSQLTransaction;
    procedure PQConnLog(Sender: TSQLConnection; EventType: TDBEventType;
      const Msg: String);
    procedure qryChainschain_nameGetText(Sender: TField; var aText: string;
      DisplayText: Boolean);
  private
  public
    procedure Connect;
    procedure Disconnect;
  end;

var
  dmPgEngine: TdmPgEngine;

implementation

uses uObjects, uMain;

{$R *.lfm}

{ TdmPgEngine }

procedure TdmPgEngine.PQConnLog(Sender: TSQLConnection;
  EventType: TDBEventType; const Msg: String);
begin
  uMain.fmMain.mmLog.Lines.Append(Msg);
  uMain.fmMain.mmLog.Lines.Append('----------------------------------------------------');
end;

procedure TdmPgEngine.qryChainschain_nameGetText(Sender: TField;
  var aText: string; DisplayText: Boolean);
begin
  aText := Sender.AsString;
end;

procedure TdmPgEngine.Connect;
begin
  qryChains.Open;
  qryTasks.Open;
end;

procedure TdmPgEngine.Disconnect;
begin
  PQConn.Close(True);
end;


end.
