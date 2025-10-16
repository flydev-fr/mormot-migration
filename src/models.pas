unit models;

interface

{$I mormot.defines.inc}

uses
  mormot.core.base,
  mormot.orm.base,
  mormot.orm.core;

type
  TOrmSample = class(TOrm)
  private
    FName: RawUTF8;
    FQuestion: RawUTF8;
    FTime: TModTime;
    FDummyOrphaned:Integer;
  published
    property Name: RawUTF8 read FName write FName;
    property Question: RawUTF8 read FQuestion write FQuestion;
    property Time: TModTime read FTime write FTime;

    // un/comment to create/clean
    //property DummyOrphaned: integer read FDummyOrphaned write FDummyOrphaned;
  end;

  function CreateSampleModel: TOrmModel;

implementation

function CreateSampleModel: TOrmModel;
begin
  result := TOrmModel.Create([TOrmSample]);
end;



end.