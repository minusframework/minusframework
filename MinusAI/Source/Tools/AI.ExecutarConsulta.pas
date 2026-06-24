unit AI.ExecutarConsulta;

interface

uses
  System.JSON, System.SysUtils, MCP.Types;

function RegistrarExecutarConsulta: TMCPTool;

implementation

function ExecutarConsultaSQL(const ASql, AConexao: string): string;
begin
  if AConexao <> '' then
    Result := 'Conectando em ' + AConexao + '...'
  else
    Result := 'Usando conexão padrão...';
  Result := Result + #13#10 +
    'SQL: ' + ASql + #13#10 +
    #13#10 +
    '[simulação] Consulta executada com sucesso. ' +
    'Para execução real, configure uma conexão FireDAC.';
end;

function ExecutarToolConsulta(const AParams: TJSONObject): TMCPToolResult;
var
  LSql, LConexao, LResultado: string;
  LArr: TJSONArray;
begin
  LSql := '';
  LConexao := '';
  if AParams <> nil then
  begin
    AParams.TryGetValue('sql', LSql);
    AParams.TryGetValue('conexao', LConexao);
  end;

  if LSql = '' then
  begin
    LArr := TJSONArray.Create;
    LArr.AddElement(TJSONObject.Create.AddPair('type', 'text')
      .AddPair('text', 'Parâmetro "sql" é obrigatório.'));
    Result.Content := LArr;
    Result.IsError := True;
    Exit;
  end;

  LResultado := ExecutarConsultaSQL(LSql, LConexao);
  LArr := TJSONArray.Create;
  LArr.AddElement(TJSONObject.Create.AddPair('type', 'text')
    .AddPair('text', LResultado));
  Result.Content := LArr;
  Result.IsError := False;
end;

function RegistrarExecutarConsulta: TMCPTool;
begin
  Result.Schema.Name := 'executar_consulta';
  Result.Schema.Description := 'Executa uma consulta SQL contra um banco de dados';
  Result.Schema.InputSchema := TJSONObject.Create;
  Result.Schema.InputSchema.AddPair('type', 'object');
  var LProps := TJSONObject.Create;
  var LSql := TJSONObject.Create;
  LSql.AddPair('type', 'string');
  LSql.AddPair('description', 'Comando SQL a ser executado');
  LProps.AddPair('sql', LSql);
  var LConn := TJSONObject.Create;
  LConn.AddPair('type', 'string');
  LConn.AddPair('description', 'Nome da conexão FireDAC (opcional)');
  LProps.AddPair('conexao', LConn);
  Result.Schema.InputSchema.AddPair('properties', LProps);
  Result.Schema.InputSchema.AddPair('required', TJSONArray.Create.AddElement('sql'));
  Result.Execute := ExecutarToolConsulta;
end;

end.
