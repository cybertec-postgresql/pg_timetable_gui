unit uDataModule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, PQConnection, SQLDB;

type

  { TdmPgEngine }

  TdmPgEngine = class(TDataModule)
    DataSource1: TDataSource;
    PQConn: TPQConnection;
    PQQuery: TSQLQuery;
    PQQuerychain_id: TLargeintField;
    PQQuerychain_name: TMemoField;
    PQQueryclient_name: TMemoField;
    PQQueryexclusive_execution: TBooleanField;
    PQQuerylive: TBooleanField;
    PQQuerymax_instances: TLongintField;
    PQQueryrun_at: TMemoField;
    PQQueryself_destruct: TBooleanField;
    PQQuerytask_id: TLargeintField;
    SQLTransaction1: TSQLTransaction;
    procedure PQConnLog(Sender: TSQLConnection; EventType: TDBEventType;
      const Msg: String);
    procedure PQQuerychain_nameGetText(Sender: TField; var aText: string;
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

procedure TdmPgEngine.PQQuerychain_nameGetText(Sender: TField;
  var aText: string; DisplayText: Boolean);
begin
  aText := Sender.AsString;
end;

procedure TdmPgEngine.Connect;
begin
  PQQuery.Open;
end;

procedure TdmPgEngine.Disconnect;
begin
  PQConn.Close(True);
end;


end.
