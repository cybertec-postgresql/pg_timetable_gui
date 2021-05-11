unit uObjects;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  { TTask }

  TCommandKind = (ckSQL, ckPROGRAM, ckBUILTIN);

  TTask = class(TCollectionItem)
  private
    FTaskID: integer;
    FKind: TCommandKind;
    FName: string;
    FScript: string;
    function GetKind: string;
    procedure SetKind(AValue: string);
    procedure SetName(AValue: string);
    procedure SetScript(AValue: string);
  published
    property TaskID: integer read FTaskID write FTaskID;
    property Name: string read FName write SetName;
    property Script: string read FScript write SetScript;
    property Kind: string read GetKind write SetKind;
  end;

  { TChain }

  TChain = class(TCollectionItem)
  private
    FChainID: integer;
    FClientName: string;
    FExclusive: boolean;
    FLive: boolean;
    FMaxInstances: integer;
    FName: string;
    FRunAt: string;
    FSelfDestruct: boolean;
    FTasks: TCollection;
    procedure SetTasks(AValue: TCollection);
  public
    constructor Create(ACollection: TCollection); override;
  published
    property ChainID: integer read FChainID write FChainID;
    property Tasks: TCollection read FTasks write SetTasks;
    property Name: string read FName write FName;
    property RunAt: string read FRunAt write FRunAt;
    property MaxInstances: integer read FMaxInstances write FMaxInstances;
    property Live: boolean read FLive write FLive;
    property SelfDestruct: boolean read FSelfDestruct write FSelfDestruct;
    property Exclusive: boolean read FExclusive write FExclusive;
    property ClientName: string read FClientName write FClientName;
  end;



const
  BuiltinCommands: array of string = ('NoOp', 'Download', 'Log');

implementation

uses TypInfo;

{ TTask }
procedure TChain.SetTasks(AValue: TCollection);
begin
  if FTasks=AValue then Exit;
  FTasks:=AValue;
end;

constructor TChain.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FTasks := TCollection.Create(TTask);
end;

{ TCommand }

procedure TTask.SetName(AValue: string);
begin
  if FName = AValue then
    Exit;
  FName := AValue;
end;

function TTask.GetKind: string;
begin
  Result := Copy(GetEnumName(TypeInfo(TCommandKind), Ord(FKind)), 3, MaxInt);
end;

procedure TTask.SetKind(AValue: string);
begin
  FKind := TCommandKind(GetEnumValue(TypeInfo(TCommandKind), 'ck' + AValue));
end;

procedure TTask.SetScript(AValue: string);
begin
  if FScript = AValue then
    Exit;
  FScript := AValue;
end;

end.
