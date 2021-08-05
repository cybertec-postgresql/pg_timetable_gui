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
    procedure PQConnLogin(Sender: TObject; Username, Password: string);
    procedure qryChainsAfterClose(DataSet: TDataSet);
    procedure qryChainsAfterDelete(DataSet: TDataSet);
    procedure qryChainsAfterInsert(DataSet: TDataSet);
    procedure qryChainsAfterPost(DataSet: TDataSet);
    procedure qryChainsBeforeDelete(DataSet: TDataSet);
  private
  public
    procedure Connect;
    procedure Disconnect;
    function IsCronValueValid(const S: string): boolean;
    function IsConnected: boolean;
  end;

var
  dmPgEngine: TdmPgEngine;

implementation

uses uObjects, fmMain, fmConnect, Dialogs, UITypes;

{$R *.lfm}

{ TdmPgEngine }

procedure TdmPgEngine.PQConnLog(Sender: TSQLConnection;
  EventType: TDBEventType; const Msg: String);
begin
  fmMain.MainForm.mmLog.Lines.Append(Msg);
  fmMain.MainForm.mmLog.Lines.Append('----------------------------------------------------');
end;

procedure TdmPgEngine.PQConnLogin(Sender: TObject; Username, Password: string);
begin
  if not fmConnect.EditDatabase(Sender as TPQConnection) then Abort();
end;

procedure TdmPgEngine.qryChainsAfterClose(DataSet: TDataSet);
begin
   with DataSet as TSQLQuery do
     IndexName := '';
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
  Q: TSQLQuery;
begin
  Q := DataSet as TSQLQuery;
  Q.IndexName := '';
  c := DataSet.FieldValues['chain_name'];
  try
    Q.ApplyUpdates;
    DataSet.Refresh;
  except
    on E: EDatabaseError do
     begin
      MessageDlg('Database Error', E.Message, mtError, [mbOK], 0);
      Q.CancelUpdates;
     end;
  end;
  DataSet.Locate('chain_name', c, []);
  fmMain.MainForm.UpdateSortIndication(nil);
end;

procedure TdmPgEngine.qryChainsBeforeDelete(DataSet: TDataSet);
begin
  if MessageDlg('Delete confirmation',
    'Are you sure you want delete current chain?', mtWarning, [mbOK, mbCancel], 0) = mrCancel then
  Abort;
end;

procedure TdmPgEngine.Connect;
begin
  qryChains.Open;
  qryTasks.Open;
  qryChains.First;
end;

procedure TdmPgEngine.Disconnect;
begin
  PQConn.Close(True);
end;

function TdmPgEngine.IsCronValueValid(const S: string): boolean;
var
  Q: TSQLQuery;
begin
  Result := True;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := PQConn;
    Q.Transaction := PQConn.Transaction;
    Q.SQL.Text := 'SELECT CAST(:cron AS timetable.cron)';
    Q.ParamByName('cron').AsString := S;
    try
      Q.Open;
    except
      Exit(False);
    end;
    Q.Close;
  finally
    FreeAndNil(Q);
  end;
end;

function TdmPgEngine.IsConnected: boolean;
begin
  Result := qryChains.Active and qryTasks.Active;
end;


end.
