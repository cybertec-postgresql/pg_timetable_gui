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
    timerChange: TTimer;
    procedure edCronChange(Sender: TObject);
    procedure timerChangeTimer(Sender: TObject);
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
begin
  timerChange.Enabled := True; //start timer to update next runs
end;

procedure TfrmCronEditor.timerChangeTimer(Sender: TObject);
var
  ValidCron: boolean;
  S: string;
  Output: string;
const
  cronRE          = '^(((\d+,)+\d+|(\d+(\/|-)\d+)|(\*(\/|-)\d+)|\d+|\*) +){4}'+
                    '(((\d+,)+\d+|(\d+(\/|-)\d+)|(\*(\/|-)\d+)|\d+|\*) ?)$';
  sqlCronRuns     = 'SELECT to_char(r.r, ''FMDay, FMDD FMMon YYYY at HH24:MI:SS'') FROM '+
                    'generate_series(now(), now() + 10 * :cron :: interval, :cron :: interval) AS r(r) LIMIT 10';
  sqlIntervalRuns = 'SELECT to_char(r.r, ''FMDay, FMDD FMMon YYYY at HH24:MI:SS'') FROM '+
                    'timetable.cron_runs(now(), :cron) AS r(r) LIMIT 10';
  minIntervalLen  = length('@every '); // @ modifier and at least one space char
begin
  timerChange.Enabled := False;
  S := edCron.Text;
  ValidCron := S.Trim() = '@reboot';
  if not ValidCron then
    if S.StartsWith('@every ') or S.StartsWith('@after ') then //special values
      ValidCron := (S.Length > minIntervalLen)
                   and dmPgEngine.IsCronValueValid(S)
                   and dmPgEngine.SelectSQL(sqlCronRuns, [S.Substring(minIntervalLen)], Output)
  else
    with TRegExpr.Create(cronRE) do
    try
      ValidCron := Exec(S) and dmPgEngine.SelectSQL(sqlIntervalRuns, [S], Output);
    finally
      Free();
    end;
  mmRuns.Text := Output;
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

