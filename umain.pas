unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics,
  Dialogs, ComCtrls, Menus, StdCtrls, DBGrids, DBCtrls, RTTIGrids, RTTICtrls,
  uObjects, PropEdits, ObjectInspector, VirtualTrees, DB;

type

  { TfmMain }

  TfmMain = class(TForm)
    btnApply: TButton;
    btnCancel: TButton;
    chkExclusive: TDBCheckBox;
    chkSelfDestruct: TDBCheckBox;
    Connect: TButton;
    edClientName: TDBEdit;
    edRunAt: TDBEdit;
    edChainName: TDBEdit;
    gbChain: TGroupBox;
    gridChains: TDBGrid;
    imglSidebar: TImageList;
    lblRunAt: TLabel;
    lblChainID: TDBText;
    lblRunAt1: TLabel;
    lblChainName: TLabel;
    mmLog: TMemo;
    menuMain: TMainMenu;
    miFile: TMenuItem;
    miClose: TMenuItem;
    miHelp: TMenuItem;
    miAbout: TMenuItem;
    procedure btnApplyClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure ConnectClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure miCloseClick(Sender: TObject);
  private
  public

  end;

var
  fmMain: TfmMain;

implementation

uses uDataModule;

{$R *.lfm}

{ TfmMain }

procedure TfmMain.ConnectClick(Sender: TObject);
begin
  dmPgEngine.Connect;
end;

procedure TfmMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  dmPgEngine.Disconnect;
  CanClose := True;
end;

procedure TfmMain.btnApplyClick(Sender: TObject);
begin
  dmPgEngine.PQQuery.Post;
end;

procedure TfmMain.btnCancelClick(Sender: TObject);
begin
  dmPgEngine.PQQuery.Cancel;
end;

procedure TfmMain.miCloseClick(Sender: TObject);
begin
  Close();
end;

end.
