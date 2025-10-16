program BasicMigration;

{$APPTYPE CONSOLE}

{$I mormot.defines.inc}

uses
  {$I mormot.uses.inc}
  mormot.core.base,
  mormot.core.os,
  mormot.core.text,
  mormot.core.log,
  mormot.db.sql.sqlite3,
  mormot.db.raw.sqlite3,
  mormot.db.raw.sqlite3.static,
  mormot.orm.core,
  mormot.orm.sql,
  mormot.rest.core,
  mormot.rest.http.server,
  orm.schema.migration in 'orm.schema.migration.pas',
  models in 'models.pas',
  server in 'server.pas';

const
  HttpPort = '8092';

var
  Model: TOrmModel;
  DBFileName: RawUtf8;
  RemoteProps: TSqlDBSQLite3ConnectionProperties;
  SampleServer: TSampleServer;
  HttpServer: TRestHttpServer;
  LogFamily: TSynLogFamily;


procedure RunSchemaMaintenance(aProps: TSqlDBSQLite3ConnectionProperties; aRest: TRest);
var
  Migrator: TOrmSchemaMigrator;
begin
  Migrator := TOrmSchemaMigrator.Create(aProps, aRest, DBFileName);
  try
    Migrator.PrintDiffs;

    // effective clean
    Migrator.RunClean;
  finally
    Migrator.Free;
  end;
end;

begin
  with TSynLog.Family do
  begin
    Level := LOG_VERBOSE;
    // EchoToConsole := LOG_VERBOSE;
    EchoToConsole := LOG_ERR + [sllDB, sllCustom1];
    NoFile := True;
  end;

  DBFileName := MakeFileName([Executable.ProgramFilePath, Executable.ProgramName, '.db']);
  Model := CreateSampleModel;
  try
    SampleServer := TSampleServer.Create(Model, DBFileName);
    try
      RemoteProps := TSqlDBSQLite3ConnectionProperties.Create(
        DBFileName, '', '', '');
      OrmMapExternal(Model, [TOrmSample], RemoteProps);
      SampleServer.Server.CreateMissingTables;
      HttpServer := TRestHttpServer.Create(HttpPort, [SampleServer],'+',HTTP_DEFAULT_MODE, 4);
      HttpServer.AccessControlAllowOrigin := '*';
      try
        ConsoleWrite('Server started on port %', [HttpPort]);

        TSynLog.Add.Log(sllCustom1, 'Running migration...');
        RunSchemaMaintenance(RemoteProps, SampleServer);

        ConsoleWaitForEnterKey;
      finally
        HttpServer.Free;
      end;
    finally
      SampleServer.Free;
    end;
  finally
    Model.Free;
    RemoteProps.ThreadSafeConnection.Disconnect;
    RemoteProps.Free;
  end;
end.
