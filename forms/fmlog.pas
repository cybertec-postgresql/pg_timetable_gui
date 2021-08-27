unit fmLog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfmLog }

  TfmLog = class(TForm)
    mmLog: TMemo;
  private

  public

  end;

var
  LogForm: TfmLog;

implementation

{$R *.lfm}

end.

