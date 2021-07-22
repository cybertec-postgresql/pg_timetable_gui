unit fmMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
  StdCtrls, DBGrids, DBCtrls, ExtCtrls, RTTIGrids, RTTICtrls, uObjects,
  PropEdits, ObjectInspector, VirtualTrees, DB, Grids, ActnList, DBActns;

type

  { TfmMain }

  TfmMain = class(TForm)
    acConnect: TAction;
    acDisconnect: TAction;
    alChains: TActionList;
    chkExclusive: TDBCheckBox;
    chkSelfDestruct: TDBCheckBox;
    acChainInsert: TDataSetInsert;
    acChainDelete: TDataSetDelete;
    acChainEdit: TDataSetEdit;
    acChainRefresh: TDataSetRefresh;
    acChainPost: TDataSetPost;
    acChainCancel: TDataSetCancel;
    gridTasks: TDBGrid;
    edClientName: TDBEdit;
    edSchedule: TDBEdit;
    edChainName: TDBEdit;
    gbChain: TGroupBox;
    gridChains: TDBGrid;
    imglNavigatorDisabled: TImageList;
    imglNavigator: TImageList;
    imglSidebar: TImageList;
    lblSchedule: TLabel;
    lblChainID: TDBText;
    lblRunAt: TLabel;
    lblChainName: TLabel;
    miConnect: TMenuItem;
    miDisconnect: TMenuItem;
    mmLog: TMemo;
    menuMain: TMainMenu;
    miFile: TMenuItem;
    miClose: TMenuItem;
    miHelp: TMenuItem;
    miAbout: TMenuItem;
    pnlChains: TPanel;
    pnlDetails: TPanel;
    splitSidebar: TSplitter;
    splitDetails: TSplitter;
    toolbarMain: TToolBar;
    btnConnect: TToolButton;
    btnChainInsert: TToolButton;
    btnSeparator: TToolButton;
    btnChainDelete: TToolButton;
    btnChainEdit: TToolButton;
    btnChainRefresh: TToolButton;
    btnChainPost: TToolButton;
    btnChainCancel: TToolButton;
    procedure acConnectUpdate(Sender: TObject);
    procedure acDisconnectExecute(Sender: TObject);
    procedure acDisconnectUpdate(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure acConnectClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure gridChainsTitleClick(Column: TColumn);
    procedure gridTasksDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: integer; Column: TColumn; State: TGridDrawState);
    procedure gridTasksEditButtonClick(Sender: TObject);
  private
    FLastColumn: TColumn; //last sorted grid column
  public

  end;

var
  MainForm: TfmMain;

implementation

uses uDataModule, SQLDB;

{$R *.lfm}

{ TfmMain }

procedure TfmMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  dmPgEngine.Disconnect;
  CanClose := True;
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
  // Remove the sort arrow from the previous column we sorted
  if Assigned(FLastColumn) and (FlastColumn <> Column) then
    FLastColumn.Title.ImageIndex := -1;
  FLastColumn := Column;
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
  aLeft := Rect.Left + Rect.Width - imglSidebar.Width - 2;
  aTop := Rect.Top + (Rect.Height - imglSidebar.Height) div 2;
  imglSidebar.Draw(gridTasks.Canvas, aLeft, aTop, ImgIdx);
end;

procedure TfmMain.gridTasksEditButtonClick(Sender: TObject);
begin
  ShowMessage(gridTasks.SelectedField.AsString);
end;

procedure TfmMain.btnCancelClick(Sender: TObject);
begin
  dmPgEngine.qryChains.Cancel;
end;

procedure TfmMain.acConnectUpdate(Sender: TObject);
begin
  //(Sender as TAction).Enabled := not dmPgEngine.PQConn.Connected;
  btnConnect.Down := dmPgEngine.PQConn.Connected;
  miConnect.Checked := btnConnect.Down;
end;

procedure TfmMain.acDisconnectExecute(Sender: TObject);
begin
  dmPgEngine.Disconnect;
end;

procedure TfmMain.acDisconnectUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := dmPgEngine.PQConn.Connected;
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
    dmPgEngine.Disconnect;
end;

end.
