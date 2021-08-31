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
    connMain: TPQConnection;
    qryChains: TSQLQuery;
    qryTasks: TSQLQuery;
    transChains: TSQLTransaction;
    procedure connMainLog(Sender: TSQLConnection; EventType: TDBEventType;
      const Msg: String);
    procedure connMainLogin(Sender: TObject; Username, Password: string);
    procedure qryChainsAfterClose(DataSet: TDataSet);
    procedure qryChainsAfterDelete(DataSet: TDataSet);
    procedure qryChainsAfterInsert(DataSet: TDataSet);
    procedure qryAfterPost(DataSet: TDataSet);
    procedure qryChainsBeforeDelete(DataSet: TDataSet);
    procedure qryTasksAfterInsert(DataSet: TDataSet);
    procedure qryTasksAfterOpen(DataSet: TDataSet);
    procedure qryTasksBeforePost(DataSet: TDataSet);
  private
    FLastTaskID: integer;
  public
    procedure Connect;
    procedure Disconnect;
    function IsCronValueValid(const S: string): boolean;
    function IsConnected: boolean;
    function SelectSQL(const sql: string): string;
    procedure MoveTaskUp(const ATaskID: integer);
    procedure MoveTaskDown(const ATaskID: integer);
    function IsTaskDeleteAllowed: boolean;
  end;

var
  dmPgEngine: TdmPgEngine;

implementation

uses uObjects, fmMain, fmConnect, Dialogs, UITypes, fmLog;

{$R *.lfm}

{ TdmPgEngine }

procedure TdmPgEngine.connMainLog(Sender: TSQLConnection;
  EventType: TDBEventType; const Msg: String);
const et: array[TDBEventType] of string = ('detCustom', 'detPrepare', 'detExecute',
'detFetch', 'detCommit', 'detRollBack', 'detParamValue', 'detActualSQL');
begin
  with fmLog.LogForm.mmLog.Lines do
  begin
    Append(Format('[%s:] %s' + LineEnding, [et[EventType], Msg]))
  end;
end;

procedure TdmPgEngine.connMainLogin(Sender: TObject; Username, Password: string);
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

procedure TdmPgEngine.qryAfterPost(DataSet: TDataSet);
var
  FldVal: variant;
  FldName: string;
  Q: TSQLQuery;
const
  FldNames: array[boolean] of string = ('chain_name', 'parent_id');
begin
  Q := DataSet as TSQLQuery;
  FldName := FldNames[Q = qryTasks];
  Q.IndexName := '';
  FldVal := DataSet.FieldValues[FldName];
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
  DataSet.Locate(FldName, FldVal, []);
  if Q = qryChains then
    fmMain.MainForm.UpdateSortIndication(nil);
end;

procedure TdmPgEngine.qryChainsBeforeDelete(DataSet: TDataSet);
begin
  if MessageDlg('Delete confirmation',
    'Are you sure you want delete current chain?', mtWarning, [mbOK, mbCancel], 0) = mrCancel then
  Abort();
end;

procedure TdmPgEngine.qryTasksAfterInsert(DataSet: TDataSet);
begin
  with DataSet do
  begin
    FieldByName('parent_id').AsInteger := FLastTaskID;
    FieldByName('kind').AsString := 'SQL';
    FieldByName('ignore_error').AsBoolean := False;
    FieldByName('autonomous').AsBoolean := False;
  end;
end;

procedure TdmPgEngine.qryTasksAfterOpen(DataSet: TDataSet);
begin
  DataSet.Last();
  FLastTaskID := DataSet.FieldByName('task_id').AsInteger;
end;

procedure TdmPgEngine.qryTasksBeforePost(DataSet: TDataSet);
begin
  if DataSet.FieldByName('command').IsNull then Abort();
end;

procedure TdmPgEngine.Connect;
begin
  qryChains.Open;
  qryTasks.Open;
  qryChains.First;
end;

procedure TdmPgEngine.Disconnect;
begin
  connMain.Close(True);
end;

function TdmPgEngine.IsCronValueValid(const S: string): boolean;
var
  Q: TSQLQuery;
begin
  Result := True;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := connMain;
    Q.Transaction := connMain.Transaction;
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

function TdmPgEngine.SelectSQL(const sql: string): string;
var
  Q: TSQLQuery;
begin
  Result := '';
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := connMain;
    Q.Transaction := connMain.Transaction;
    Q.SQL.Text := sql;
    try
      Q.Open;
      while not Q.EOF do
      begin
        Result := Result + LineEnding + Q.Fields[0].AsString;
        Q.Next;
      end;
    except
      Exit;
    end;
    Q.Close;
  finally
    FreeAndNil(Q);
  end;
end;

procedure TdmPgEngine.MoveTaskUp(const ATaskID: integer);
begin
  connMain.ExecuteDirect(Format('SELECT timetable.move_task_up(%d)', [ATaskID]));
end;

procedure TdmPgEngine.MoveTaskDown(const ATaskID: integer);
begin
  connMain.ExecuteDirect(Format('SELECT timetable.move_task_down(%d)', [ATaskID]));
end;

function TdmPgEngine.IsTaskDeleteAllowed: boolean;
begin
  Result := not qryTasks.BOF and not qryTasks.EOF and not qryTasks.FieldByName('parent_id').IsNull;
end;

end.
