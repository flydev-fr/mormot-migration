unit orm.schema.migration;

interface

{$I mormot.defines.inc}

uses
  mormot.core.base,
  mormot.core.os,
  mormot.core.text,
  mormot.core.data,
  mormot.core.unicode,
  mormot.core.log,
  mormot.orm.core,
  mormot.orm.base,
  mormot.db.core,
  mormot.db.sql,
  mormot.db.sql.sqlite3,
  mormot.db.raw.sqlite3,
  mormot.rest.core,
  mormot.rest.server;

type
  // simple structure to store diff information
  TOrmSchemaDiff = record
    TableName: RawUtf8;
    OrphanColumns: TRawUtf8DynArray;
  end;

  TOrmSchemaDiffDynArray = array of TOrmSchemaDiff;

  // minimal schema migration helper
  TOrmSchemaMigrator = class
  private
    // could be mysql, postgresl (zeos)
    fRemoteProps: TSqlDBSQLite3ConnectionProperties;
    fRest: TRest;
    fDiffs: TOrmSchemaDiffDynArray;
    procedure DetectOrphans;
    procedure DropColumn(const TableName, ColumnName: RawUtf8);
  public
    constructor Create(aProps: TSqlDBSQLite3ConnectionProperties; aRest: TRest;
      aDBFileName: RawUtf8);
    procedure RunClean;
    procedure PrintDiffs;
  end;

implementation

{ TOrmSchemaMigrator }

constructor TOrmSchemaMigrator.Create(aProps: TSqlDBSQLite3ConnectionProperties;
  aRest: TRest; aDBFileName: RawUtf8);
begin
  inherited Create;
  fRemoteProps := aProps;
  fRest := aRest;
end;

// detect columns that exist in the DB but not in the TOrm model
procedure TOrmSchemaMigrator.DetectOrphans;
var
  table: TOrmClass;
  tbl: TOrmTable;
  modelFields: TRawUtf8DynArray;
  dbFields: TSqlDBColumnDefineDynArray;
  orphanFields: TRawUtf8DynArray;
  diff: TOrmSchemaDiff;
  i, j: PtrInt;
  col: RawUtf8;
  found: boolean;
  dyn: TDynArray;
begin
  dyn.Init(TypeInfo(TOrmSchemaDiffDynArray), fDiffs);
  // clean array from dry-run
  if not dyn.ClearSafe then
    Exit;

  for table in fRest.Model.Tables do
  begin
    // get DB column names
    fRemoteProps.GetFields(table.SqlTableName, dbFields);

    // get Model published properties
    modelFields := CsvToRawUtf8DynArray
      (table.OrmProps.SqlTableRetrieveAllFields);

    // compare
    SetLength(orphanFields, 0);
    for i := 0 to High(dbFields) do
    begin
      col := dbFields[i].ColumnName;
      found := false;
      // skip ID/RowID
      if col = 'ID' then
        Continue;

      for j := 0 to High(modelFields) do
        if SameTextU(col, modelFields[j]) then
        begin
          found := true;
          break;
        end;
      if not found then
      begin
        AddRawUtf8(orphanFields, col);
      end;
    end;

    if Length(orphanFields) > 0 then
    begin
      diff.TableName := table.SqlTableName;
      diff.OrphanColumns := orphanFields;
      dyn.Add(diff);
    end;
  end;
end;

// drop a column from the DB
procedure TOrmSchemaMigrator.DropColumn(const TableName, ColumnName: RawUtf8);
begin
  fRest.Orm.ExecuteFmt('ALTER TABLE % DROP COLUMN %',
    [TableName, ColumnName]);
end;

// run the clean process (drop orphan columns)
procedure TOrmSchemaMigrator.RunClean;
var
  d: TOrmSchemaDiff;
  c: RawUtf8;
begin
  DetectOrphans;
  for d in fDiffs do
    for c in d.OrphanColumns do
      DropColumn(d.TableName, c);
end;

// print diffs (dry-run)
procedure TOrmSchemaMigrator.PrintDiffs;
var
  d: TOrmSchemaDiff;
  c: RawUtf8;
begin
  DetectOrphans;
  if Length(fDiffs) = 0 then
  begin
    TSynLog.Add.Log(sllCustom1, 'No orphan columns found. Schema is clean.');
    exit;
  end;

  for d in fDiffs do
  begin
    TSynLog.Add.Log(sllCustom1, 'Table: %', [d.TableName]);
    for c in d.OrphanColumns do
      TSynLog.Add.Log(sllCustom1, '  Orphan column: %', [c]);
  end;
end;

end.
