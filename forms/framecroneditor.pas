unit frameCronEditor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  framebase;

type

  { TfrmCronEditor }

  TfrmCronEditor = class(TBaseFrame)
    edCron: TEdit;
    lblNextRuns: TLabel;
    lblDayMonth: TLabel;
    lblHour: TLabel;
    lblMinute: TLabel;
    lblWeekday: TLabel;
    lblMonth: TLabel;
    mmRuns: TMemo;
    pnlEditor: TPanel;
    procedure edCronChange(Sender: TObject);
  private

  public
    function GetEditorValue(): string; override;
    procedure SetEditorValue(AText: string); override;
    procedure SetFocus; override;
  end;

implementation

uses RegExpr, uDataModule;

{$R *.lfm}

{ TfrmCronEditor }

procedure TfrmCronEditor.edCronChange(Sender: TObject);
var
  ValidCron: boolean;
  S: string;
const
  cronRE          = '^(((\d+,)+\d+|(\d+(\/|-)\d+)|(\*(\/|-)\d+)|\d+|\*) +){4}'+
                    '(((\d+,)+\d+|(\d+(\/|-)\d+)|(\*(\/|-)\d+)|\d+|\*) ?)$';
  sqlCronRuns     = 'SELECT to_char(r.r, ''FMDay, FMDD FMMon YYYY at HH24:MI:SS'') FROM '+
                    'generate_series(now(), now() + 10 * :cron :: interval, :cron :: interval) AS r(r) LIMIT 10';
  sqlIntervalRuns = 'SELECT to_char(r.r, ''FMDay, FMDD FMMon YYYY at HH24:MI:SS'') FROM '+
                    'timetable.cron_runs(now(), $1) AS r(r) LIMIT 10';
  minIntervalLen  = length('@every '); // @ modifier and at least one space char
begin
  S := edCron.Text;
  ValidCron := S.Trim() = '@reboot';
  if not ValidCron then
    if S.StartsWith('@every ') or S.StartsWith('@after ') then //special values
    begin
      ValidCron := (S.Length > minIntervalLen) and dmPgEngine.IsCronValueValid(S);
      if ValidCron then
        mmRuns.Text := dmPgEngine.SelectSQL(sqlCronRuns, [S.Substring(minIntervalLen)]);
    end
  else
    with TRegExpr.Create(cronRE) do
    try
      ValidCron := Exec(S);
      if ValidCron then
        mmRuns.Text := dmPgEngine.SelectSQL(sqlIntervalRuns, [S]);
    finally
      Free();
    end;
  if ValidCron then edCron.Color := clDefault else edCron.Color := clRed;
end;

function TfrmCronEditor.GetEditorValue: string;
begin
  Exit(edCron.Text);
end;

procedure TfrmCronEditor.SetEditorValue(AText: string);
begin
  edCron.Text := AText;
end;

procedure TfrmCronEditor.SetFocus;
begin
  edCron.SetFocus();
end;

end.

