unit AI.GerarEntidade;

interface

uses
  System.JSON, System.SysUtils, MCP.Types;

function RegistrarGerarEntidade: TMCPTool;

implementation

function GerarEntidade(const ANomeTabela, AConexao: string): string;
var
  LClasse: string;
begin
  LClasse := ANomeTabela.Trim;
  if LClasse = '' then
    LClasse := 'MinhaEntidade';
  LClasse[1] := UpperCase(LClasse[1])[1];
  Result :=
    'unit MinusAI.Gen.' + LClasse + ';' + #13#10 +
    #13#10 +
    'interface' + #13#10 +
    #13#10 +
    'uses' + #13#10 +
    '  MF.ORM.Entity;' + #13#10 +
    #13#10 +
    'type' + #13#10 +
    '  [' + LowerCase(ANomeTabela) + ']' + #13#10 +
    '  T' + LClasse + ' = class(TMFEntity)' + #13#10 +
    '  private' + #13#10 +
    '    FId: Integer;' + #13#10 +
    '    FNome: string;' + #13#10 +
    '  public' + #13#10 +
    '    property Id: Integer read FId write FId;' + #13#10 +
    '    property Nome: string read FNome write FNome;' + #13#10 +
    '  end;' + #13#10 +
    #13#10 +
    'implementation' + #13#10 +
    #13#10 +
    'end.';
end;

function ExecutarGerarEntidade(const AParams: TJSONObject): TMCPToolResult;
var
  LNomeTabela, LConexao, LResultado: string;
  LArr: TJSONArray;
begin
  LNomeTabela := '';
  LConexao := '';
  if AParams <> nil then
  begin
    AParams.TryGetValue('tabela', LNomeTabela);
    AParams.TryGetValue('conexao', LConexao);
  end;

  if LNomeTabela = '' then
  begin
    LArr := TJSONArray.Create;
    LArr.AddElement(TJSONObject.Create.AddPair('type', 'text')
      .AddPair('text', 'Parâmetro "tabela" é obrigatório.'));
    Result.Content := LArr;
    Result.IsError := True;
    Exit;
  end;

  LResultado := GerarEntidade(LNomeTabela, LConexao);
  LArr := TJSONArray.Create;
  LArr.AddElement(TJSONObject.Create.AddPair('type', 'text')
    .AddPair('text', LResultado));
  Result.Content := LArr;
  Result.IsError := False;
end;

function RegistrarGerarEntidade: TMCPTool;
begin
  Result.Schema.Name := 'gerar_entidade';
  Result.Schema.Description := 'Gera código de entidade ORM a partir do nome da tabela';
  Result.Schema.InputSchema := TJSONObject.Create;
  Result.Schema.InputSchema.AddPair('type', 'object');
  var LProps := TJSONObject.Create;
  var LTab := TJSONObject.Create;
  LTab.AddPair('type', 'string');
  LTab.AddPair('description', 'Nome da tabela no banco');
  LProps.AddPair('tabela', LTab);
  var LConn := TJSONObject.Create;
  LConn.AddPair('type', 'string');
  LConn.AddPair('description', 'Nome da conexão FireDAC');
  LProps.AddPair('conexao', LConn);
  Result.Schema.InputSchema.AddPair('properties', LProps);
  Result.Schema.InputSchema.AddPair('required', TJSONArray.Create.AddElement('tabela'));
  Result.Execute := ExecutarGerarEntidade;
end;

end.
