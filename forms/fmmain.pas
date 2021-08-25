unit fmMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
  StdCtrls, DBGrids, DBCtrls, ExtCtrls, RTTIGrids, RTTICtrls, uObjects,
  PropEdits, ObjectInspector, VirtualTrees, DB, Grids, ActnList, Buttons;

type

  { TfmMain }

  TfmMain = class(TForm)
    acConnect: TAction;
    acMoveTaskUp: TAction;
    acMoveTaskDown: TAction;
    acTaskDelete: TAction;
    acTaskAdd: TAction;
    acTaskEdit: TAction;
    acTaskPost: TAction;
    acTaskCancel: TAction;
    acTaskRefresh: TAction;
    acChainAdd: TAction;
    acChainDelete: TAction;
    acChainEdit: TAction;
    acChainPost: TAction;
    acChainCancel: TAction;
    acChainRefresh: TAction;
    alToolbars: TActionList;
    btnTaskMoveUp: TToolButton;
    gridTasks: TDBGrid;
    gridChains: TDBGrid;
    imglToolbarsDisabled: TImageList;
    imglToolbars: TImageList;
    imglGrids: TImageList;
    miConnect: TMenuItem;
    mmLog: TMemo;
    menuMain: TMainMenu;
    miFile: TMenuItem;
    miClose: TMenuItem;
    miHelp: TMenuItem;
    miAbout: TMenuItem;
    pnlMainToolbar: TPanel;
    pnlChains: TPanel;
    pnlDetails: TPanel;
    splitChain: TSplitter;
    splitDetails: TSplitter;
    toolbarChains: TToolBar;
    toolbarMain: TToolBar;
    btnConnect: TToolButton;
    toolbarTasks: TToolBar;
    btnTaskMoveDown: TToolButton;
    btnTaskAdd: TToolButton;
    btnTaskSep1: TToolButton;
    btnTaskDelete: TToolButton;
    btnTaskEdit: TToolButton;
    btnTaskPost: TToolButton;
    btnTaskCancel: TToolButton;
    btnTaskRefresh: TToolButton;
    btnChainAdd: TToolButton;
    btnChainDelete: TToolButton;
    btnChainEdit: TToolButton;
    btnChainPost: TToolButton;
    btnChainCancel: TToolButton;
    btnChainRefresh: TToolButton;
    procedure acChainAddExecute(Sender: TObject);
    procedure acChainCancelExecute(Sender: TObject);
    procedure acChainDeleteExecute(Sender: TObject);
    procedure acChainEditExecute(Sender: TObject);
    procedure acChainPostExecute(Sender: TObject);
    procedure acChainRefreshExecute(Sender: TObject);
    procedure acChainToolbarUpdate(Sender: TObject);
    procedure acMoveTaskDownExecute(Sender: TObject);
    procedure acMoveTaskUpExecute(Sender: TObject);
    procedure acTaskAddExecute(Sender: TObject);
    procedure acTaskCancelExecute(Sender: TObject);
    procedure acTaskDeleteExecute(Sender: TObject);
    procedure acTaskEditExecute(Sender: TObject);
    procedure acTaskPostExecute(Sender: TObject);
    procedure acTaskRefreshExecute(Sender: TObject);
    procedure acTaskToolbarUpdate(Sender: TObject);
    procedure acConnectClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure gridChainsEditingDone(Sender: TObject);
    procedure gridChainsTitleClick(Column: TColumn);
    procedure gridTasksDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: integer; Column: TColumn; State: TGridDrawState);
    procedure gridTasksSelectEditor(Sender: TObject; Column: TColumn;
      var Editor: TWinControl);
    procedure miCloseClick(Sender: TObject);
  private
    FLastColumn: TColumn; //last sorted grid column
  public
    procedure UpdateSortIndication(ACol: TColumn);
  end;

var
  MainForm: TfmMain;

implementation

uses uDataModule, SQLDB, LCLType, RegExpr;

{$R *.lfm}

{ TfmMain }

procedure TfmMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  dmPgEngine.Disconnect;
  CanClose := True;
end;

procedure TfmMain.gridChainsEditingDone(Sender: TObject);
var
  S: string;
  F: TField;
begin
  F := gridChains.SelectedField;
  if not Assigned(F) or (F.FieldName <> 'run_at') or gridChains.EditorMode then
    Exit;
  S := F.AsString;
  if not dmPgEngine.IsCronValueValid(S) then
    MessageDlg('Cron Syntax Error', 'You have error in the cron value: ' + S,
      mtError, [mbOK], 0);
end;

procedure TfmMain.gridChainsTitleClick(Column: TColumn);
const
  imgArrowUp = 3;
  imgArrowDown = 4;
var
  ASC_IndexName, DESC_IndexName: string;
  AQuery: TSQLQuery;

  procedure UpdateIndexes;
  begin
    // Ensure index defs are up to date
    AQuery.IndexDefs.Updated := False; {<<<--This line is critical. IndexDefs.Update will not
    update if already true, which will happen on the first column sorted.}
    AQuery.IndexDefs.Update;
  end;

begin
  AQuery := Column.Field.DataSet as TSQLQuery;
  ASC_IndexName := 'ASC_' + Column.FieldName;
  DESC_IndexName := 'DESC_' + Column.FieldName;
  // indexes can't sort binary types such as ftMemo, ftBLOB
  if (Column.Field.DataType in [ftBLOB, ftMemo, ftWideMemo]) then
    Exit;
  // check if an ascending index already exists for this column.
  // if not, create one
  if AQuery.IndexDefs.IndexOf(ASC_IndexName) = -1 then
  begin
    AQuery.AddIndex(ASC_IndexName, column.FieldName, []);
    UpdateIndexes; //ensure index defs are up to date
  end;
  // Check if a descending index already exists for this column
  // if not, create one
  if AQuery.IndexDefs.IndexOf(DESC_IndexName) = -1 then
  begin
    AQuery.AddIndex(DESC_IndexName, column.FieldName, [ixDescending]);
    UpdateIndexes; //ensure index defs are up to date
  end;

  // Use the column tag to toggle ASC/DESC
  Column.Tag := not Column.Tag;
  if boolean(Column.Tag) then
  begin
    Column.Title.ImageIndex := imgArrowUp;
    AQuery.IndexName := ASC_IndexName;
  end
  else
  begin
    Column.Title.ImageIndex := imgArrowDown;
    AQuery.IndexName := DESC_IndexName;
  end;
  UpdateSortIndication(Column);
end;

procedure TfmMain.gridTasksDrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: integer; Column: TColumn; State: TGridDrawState);
var
  ImgIdx, aLeft, aTop: integer;
begin
  if Column.FieldName <> 'kind' then
    Exit;
  case Column.Field.AsString of
    'SQL': ImgIdx := 0;
    'PROGRAM': ImgIdx := 1;
    else
      ImgIdx := 2;
  end;
  aLeft := Rect.Left + Rect.Width - imglGrids.Width - 2;
  aTop := Rect.Top + (Rect.Height - imglGrids.Height) div 2;
  imglGrids.Draw(gridTasks.Canvas, aLeft, aTop, ImgIdx);
end;

procedure TfmMain.gridTasksSelectEditor(Sender: TObject; Column: TColumn;
  var Editor: TWinControl);
begin
  if Column.FieldName = 'kind' then
    with Editor as TCustomComboBox do
    begin
      Style := csDropDownList;
      AutoDropDown := True;
    end;
end;

procedure TfmMain.miCloseClick(Sender: TObject);
begin
  Close();
end;

procedure TfmMain.UpdateSortIndication(ACol: TColumn);
begin
  // Remove the sort arrow from the previous column we sorted
  if Assigned(FLastColumn) and (FLastColumn <> ACol) then
    FLastColumn.Title.ImageIndex := -1;
  FLastColumn := ACol;
end;

procedure TfmMain.acChainToolbarUpdate(Sender: TObject);
var
  CanModify: boolean;
begin
  CanModify := dmPgEngine.IsConnected() and dmPgEngine.qryTasks.CanModify;
  acChainAdd.Enabled := CanModify;
  acChainDelete.Enabled := CanModify and
    (not (dmPgEngine.qryChains.BOF and dmPgEngine.qryChains.EOF));
  acChainEdit.Enabled := CanModify and not (dmPgEngine.qryChains.State in dsEditModes);
  acChainPost.Enabled := CanModify and (dmPgEngine.qryChains.State in dsEditModes);
  acChainCancel.Enabled := CanModify and (dmPgEngine.qryChains.State in dsEditModes);
  acChainRefresh.Enabled := CanModify;
end;

procedure TfmMain.acMoveTaskDownExecute(Sender: TObject);
var idx: integer;
begin
  with dmPgEngine do
  begin
    gridTasks.BeginUpdate;
    try
      idx := qryTasks.RecNo;
      MoveTaskDown(qryTasks.FieldByName('task_id').AsInteger);
      qryTasks.Refresh;
      qryTasks.RecNo := idx + 1;
    finally
      gridTasks.EndUpdate();
    end;
  end;
end;

procedure TfmMain.acMoveTaskUpExecute(Sender: TObject);
var idx: integer;
begin
  with dmPgEngine do
  begin
    gridTasks.BeginUpdate;
    try
      idx := qryTasks.RecNo;
      MoveTaskUp(qryTasks.FieldByName('task_id').AsInteger);
      qryTasks.Refresh;
      qryTasks.RecNo := idx - 1;
    finally
      gridTasks.EndUpdate();
    end;
  end;
end;

procedure TfmMain.acChainAddExecute(Sender: TObject);
begin
  dmPgEngine.qryChains.Append;
end;

procedure TfmMain.acChainCancelExecute(Sender: TObject);
begin
  dmPgEngine.qryChains.Cancel;
end;

procedure TfmMain.acChainDeleteExecute(Sender: TObject);
begin
  dmPgEngine.qryChains.Delete;
end;

procedure TfmMain.acChainEditExecute(Sender: TObject);
begin
  dmPgEngine.qryChains.Edit;
end;

procedure TfmMain.acChainPostExecute(Sender: TObject);
begin
  dmPgEngine.qryChains.Post;
end;

procedure TfmMain.acChainRefreshExecute(Sender: TObject);
begin
  dmPgEngine.qryChains.Refresh;
end;

procedure TfmMain.acTaskAddExecute(Sender: TObject);
begin
  dmPgEngine.qryTasks.Append;
end;

procedure TfmMain.acTaskCancelExecute(Sender: TObject);
begin
  dmPgEngine.qryTasks.Cancel;
end;

procedure TfmMain.acTaskDeleteExecute(Sender: TObject);
begin
  dmPgEngine.qryTasks.Delete;
end;

procedure TfmMain.acTaskEditExecute(Sender: TObject);
begin
  dmPgEngine.qryTasks.Edit;
end;

procedure TfmMain.acTaskPostExecute(Sender: TObject);
begin
  dmPgEngine.qryTasks.Post;
end;

procedure TfmMain.acTaskRefreshExecute(Sender: TObject);
begin
  dmPgEngine.qryTasks.Refresh;
end;

procedure TfmMain.acTaskToolbarUpdate(Sender: TObject);
var
  CanModify: boolean;
begin
  CanModify := dmPgEngine.IsConnected() and dmPgEngine.qryTasks.CanModify;
  acTaskAdd.Enabled := CanModify;
  acMoveTaskUp.Enabled := CanModify and (dmPgEngine.qryTasks.RecNo > 1);
  acMoveTaskDown.Enabled := CanModify and (dmPgEngine.qryTasks.RecNo < dmPgEngine.qryTasks.RecordCount);
  acTaskDelete.Enabled := CanModify and
    (not (dmPgEngine.qryTasks.BOF and dmPgEngine.qryTasks.EOF));
  acTaskEdit.Enabled := CanModify and not (dmPgEngine.qryTasks.State in dsEditModes);
  acTaskPost.Enabled := CanModify and (dmPgEngine.qryTasks.State in dsEditModes);
  acTaskCancel.Enabled := CanModify and (dmPgEngine.qryTasks.State in dsEditModes);
  acTaskRefresh.Enabled := CanModify;
end;

procedure TfmMain.acConnectClick(Sender: TObject);
begin
  if not dmPgEngine.PQConn.Connected then
    try
      dmPgEngine.Connect;
    except
      on EAbort do
        mmLog.Lines.Append('Connection cancelled by the user');
      on E: Exception do
        MessageDlg('PostgreSQL Error', E.Message, mtError, [mbOK], 0);
    end
  else
  begin
    dmPgEngine.Disconnect;
    UpdateSortIndication(nil);
  end;
end;

end.
