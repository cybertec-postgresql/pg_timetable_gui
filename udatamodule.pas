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
    procedure qryChainsAfterDelete(DataSet: TDataSet);
    procedure qryChainsAfterInsert(DataSet: TDataSet);
    procedure qryChainsAfterPost(DataSet: TDataSet);
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

procedure TdmPgEngine.qryChainsAfterDelete(DataSet: TDataSet);
begin
  (DataSet as TSQLQuery).ApplyUpdates;
end;

procedure TdmPgEngine.qryChainsAfterInsert(DataSet: TDataSet);
begin
  with DataSet do
  begin
    FieldByName('live').AsBoolean := True;
    FieldByName('self_destruct').AsBoolean := False;
    FieldByName('exclusive_execution').AsBoolean := False;
    FieldByName('run_at').AsString := '* * * * *';
  end;
end;

procedure TdmPgEngine.qryChainsAfterPost(DataSet: TDataSet);
var
  c: variant;
begin
  c := DataSet.FieldValues['chain_name'];
  (DataSet as TSQLQuery).ApplyUpdates;
  DataSet.Refresh;
  DataSet.Locate('chain_name', c, []);
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
