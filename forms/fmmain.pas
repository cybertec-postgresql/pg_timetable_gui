unit fmMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
  StdCtrls, DBGrids, DBCtrls, ExtCtrls, RTTIGrids, RTTICtrls, uObjects,
  PropEdits, ObjectInspector, VirtualTrees, DB, Grids, ActnList, DBActns,
  Buttons;

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
    alToolbars: TActionList;
    btnTaskMoveUp: TToolButton;
    dbnavChains: TDBNavigator;
    dbnavTasks: TDBNavigator;
    gridTasks: TDBGrid;
    gridChains: TDBGrid;
    ImageList1: TImageList;
    imglDBNavigator: TImageList;
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
    splitSidebar: TSplitter;
    splitDetails: TSplitter;
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
    procedure acDisconnectExecute(Sender: TObject);
    procedure acDisconnectUpdate(Sender: TObject);
    procedure acTaskAddExecute(Sender: TObject);
    procedure acTaskCancelExecute(Sender: TObject);
    procedure acTaskDeleteExecute(Sender: TObject);
    procedure acTaskEditExecute(Sender: TObject);
    procedure acTaskPostExecute(Sender: TObject);
    procedure acTaskRefreshExecute(Sender: TObject);
    procedure acUpdateToolbarsUpdate(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure acConnectClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure gridChainsEditingDone(Sender: TObject);
    procedure gridChainsTitleClick(Column: TColumn);
    procedure gridTasksDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: integer; Column: TColumn; State: TGridDrawState);
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
  if not Assigned(F) or (F.FieldName <> 'run_at') or gridChains.EditorMode then Exit;
  S := F.AsString;
  if not dmPgEngine.IsCronValueValid(S) then
    MessageDlg('Cron Syntax Error', 'You have error in the cron value: ' + S, mtError, [mbOK], 0);
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

procedure TfmMain.btnCancelClick(Sender: TObject);
begin
  dmPgEngine.qryChains.Cancel;
end;

procedure TfmMain.acDisconnectExecute(Sender: TObject);
begin
  dmPgEngine.Disconnect;
end;

procedure TfmMain.acDisconnectUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := dmPgEngine.PQConn.Connected;
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

procedure TfmMain.acUpdateToolbarsUpdate(Sender: TObject);
  var
    CanModify: Boolean;
begin
    CanModify := dmPgEngine.IsConnected() and dmPgEngine.qryTasks.CanModify;
    acTaskAdd.Enabled := CanModify;
    acMoveTaskUp.Enabled := CanModify and not dmPgEngine.qryTasks.BOF;
    acMoveTaskDown.Enabled := CanModify and not dmPgEngine.qryTasks.EOF;
    acTaskDelete.Enabled:= CanModify and (not (dmPgEngine.qryTasks.BOF and dmPgEngine.qryTasks.EOF));
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
