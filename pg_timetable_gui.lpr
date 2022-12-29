program pg_timetable_gui;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads} cthreads, {$ENDIF} {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  lazcontrols,
  fmMain, fmConnect,
  uDataModule,
  uObjects;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TfmMain, MainForm);
  Application.CreateForm(TdmPgEngine, dmPgEngine);
  Application.Run;
end.
