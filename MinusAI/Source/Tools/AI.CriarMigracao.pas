unit AI.CriarMigracao;

interface

uses
  System.JSON, System.SysUtils, System.DateUtils, MCP.Types;

function RegistrarCriarMigracao: TMCPTool;

implementation

function GerarMigracao(const ADescricao: string): string;
var
  LData: string;
  LNomeArquivo: string;
begin
  LData := FormatDateTime('yyyy-mm-dd-hhnnss', Now);
  LNomeArquivo := LData + '_' + ADescricao.Replace(' ', '_').ToLower + '.pas';
  Result :=
    '// Migration: ' + LNomeArquivo + #13#10 +
    '// Descricao: ' + ADescricao + #13#10 +
    #13#10 +
    'unit Migracao_' + LData.Replace('-', '').Replace(':', '') + ';' + #13#10 +
    #13#10 +
    'interface' + #13#10 +
    #13#10 +
    'uses' + #13#10 +
    '  MF.Migrator;' + #13#10 +
    #13#10 +
    'type' + #13#10 +
    '  [' + ADescricao.Replace(' ', '_').ToLower + ']' + #13#10 +
    '  TMigracao' + LData.Replace('-', '').Replace(':', '') + ' = class(TMigracao)' + #13#10 +
    '  public' + #13#10 +
    '    procedure Up; override;' + #13#10 +
    '    procedure Down; override;' + #13#10 +
    '  end;' + #13#10 +
    #13#10 +
    'implementation' + #13#10 +
    #13#10 +
    'procedure TMigracao' + LData.Replace('-', '').Replace(':', '') + '.Up;' + #13#10 +
    'begin' + #13#10 +
    '  // TODO: escrever SQL de upgrade' + #13#10 +
    '  // Sql.Add(''CREATE TABLE ...'');' + #13#10 +
    'end;' + #13#10 +
    #13#10 +
    'procedure TMigracao' + LData.Replace('-', '').Replace(':', '') + '.Down;' + #13#10 +
    'begin' + #13#10 +
    '  // TODO: escrever SQL de downgrade' + #13#10 +
    '  // Sql.Add(''DROP TABLE ...'');' + #13#10 +
    'end;' + #13#10 +
    #13#10 +
    'end.';
end;

function ExecutarCriarMigracao(const AParams: TJSONObject): TMCPToolResult;
var
  LDescricao: string;
  LArr: TJSONArray;
begin
  LDescricao := '';
  if AParams <> nil then
    AParams.TryGetValue('descricao', LDescricao);

  if LDescricao = '' then
  begin
    LArr := TJSONArray.Create;
    LArr.AddElement(TJSONObject.Create.AddPair('type', 'text')
      .AddPair('text', 'Parâmetro "descricao" é obrigatório.'));
    Result.Content := LArr;
    Result.IsError := True;
    Exit;
  end;

  LArr := TJSONArray.Create;
  LArr.AddElement(TJSONObject.Create.AddPair('type', 'text')
    .AddPair('text', GerarMigracao(LDescricao)));
  Result.Content := LArr;
  Result.IsError := False;
end;

function RegistrarCriarMigracao: TMCPTool;
begin
  Result.Schema.Name := 'criar_migracao';
  Result.Schema.Description := 'Gera um arquivo de migração MinusMigrator a partir de uma descrição';
  Result.Schema.InputSchema := TJSONObject.Create;
  Result.Schema.InputSchema.AddPair('type', 'object');
  var LProps := TJSONObject.Create;
  var LDesc := TJSONObject.Create;
  LDesc.AddPair('type', 'string');
  LDesc.AddPair('description', 'Descrição da migração (ex: "criar tabela usuarios")');
  LProps.AddPair('descricao', LDesc);
  Result.Schema.InputSchema.AddPair('properties', LProps);
  Result.Schema.InputSchema.AddPair('required', TJSONArray.Create.AddElement('descricao'));
  Result.Execute := ExecutarCriarMigracao;
end;

end.
