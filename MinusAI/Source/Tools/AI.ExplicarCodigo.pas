unit AI.ExplicarCodigo;

interface

uses
  System.JSON, System.SysUtils, System.IOUtils, System.Classes,
  MCP.Types;

function RegistrarExplicarCodigo: TMCPTool;

implementation

function ExtrairUnitName(const AConteudo: string): string;
var
  LMatch: string;
begin
  for var LLinha in AConteudo.Split([#13#10, #10]) do
  begin
    LMatch := LLinha.Trim;
    if LMatch.ToLower.StartsWith('unit ') then
      Exit(LMatch.Substring(5).TrimEnd([';', ' ']));
  end;
  Result := '(desconhecido)';
end;

function ExtrairUses(const AConteudo: string): TArray<string>;
var
  LInUses: Boolean;
  LLista: TList<string>;
begin
  LInUses := False;
  LLista := TList<string>.Create;
  try
    for var LLinha in AConteudo.Split([#13#10, #10]) do
    begin
      var LTrim := LLinha.Trim;
      if not LInUses and LTrim.ToLower.StartsWith('uses') then
      begin
        LInUses := True;
        LTrim := LTrim.Substring(4).Trim;
      end;
      if LInUses then
      begin
        if LTrim.Contains(';') then
        begin
          LLista.AddRange(LTrim.TrimEnd([';']).Split([',']));
          Break;
        end
        else
          LLista.AddRange(LTrim.Split([',']));
      end;
    end;
    Result := LLista.ToArray;
  finally
    LLista.Free;
  end;
end;

function ExtrairClasses(const AConteudo: string): TJSONArray;
var
  LArr: TJSONArray;
begin
  LArr := TJSONArray.Create;
  for var LLinha in AConteudo.Split([#13#10, #10]) do
  begin
    var LTrim := LLinha.Trim;
    if LTrim.StartsWith('type') then
      Continue;
    if (LTrim.StartsWith('  ')) and (LTrim.Contains('= class')) then
    begin
      var LCls := LTrim.Split(['='])[0].Trim;
      var LPai := '';
      var LHerda := LTrim.Substring(LTrim.IndexOf('class') + 5).Trim;
      if LHerda.StartsWith('(') then
        LPai := LHerda.Trim(['(', ')']);
      var LObj := TJSONObject.Create;
      LObj.AddPair('nome', LCls);
      if LPai <> '' then
        LObj.AddPair('herda_de', LPai);
      LArr.AddElement(LObj);
    end;
  end;
  Result := LArr;
end;

function ContarLinhas(const AConteudo: string): Integer;
begin
  Result := Length(AConteudo.Split([#13#10, #10]));
end;

function ExecutarExplicarCodigo(const AParams: TJSONObject): TMCPToolResult;
var
  LCaminho: string;
  LConteudo: string;
  LResult: TJSONObject;
  LArr: TJSONArray;
begin
  LCaminho := '';
  if AParams <> nil then
    AParams.TryGetValue('caminho', LCaminho);

  if (LCaminho = '') or not TFile.Exists(LCaminho) then
  begin
    LArr := TJSONArray.Create;
    LArr.AddElement(TJSONObject.Create.AddPair('type', 'text').AddPair('text',
      'Arquivo não encontrado. Informe um caminho válido para um arquivo .pas.'));
    Result.Content := LArr;
    Result.IsError := True;
    Exit;
  end;

  LConteudo := TFile.ReadAllText(LCaminho);
  LResult := TJSONObject.Create;
  LResult.AddPair('arquivo', ExtractFileName(LCaminho));
  LResult.AddPair('unit', ExtrairUnitName(LConteudo));
  LResult.AddPair('linhas', TJSONNumber.Create(ContarLinhas(LConteudo)));

  var LUses := ExtrairUses(LConteudo);
  var LJArr := TJSONArray.Create;
  for var LU in LUses do
    LJArr.AddElement(TJSONString.Create(LU.Trim));
  LResult.AddPair('uses', LJArr);

  LResult.AddPair('classes', ExtrairClasses(LConteudo));

  LArr := TJSONArray.Create;
  LArr.AddElement(TJSONObject.Create.AddPair('type', 'text').AddPair('text',
    LResult.ToJSON));
  Result.Content := LArr;
  Result.IsError := False;
  LResult.Free;
end;

function RegistrarExplicarCodigo: TMCPTool;
begin
  Result.Schema.Name := 'explicar_codigo';
  Result.Schema.Description := 'Analisa um arquivo .pas e retorna sua estrutura: unit, uses, classes, linhas';
  Result.Schema.InputSchema := TJSONObject.Create;
  Result.Schema.InputSchema.AddPair('type', 'object');
  var LProps := TJSONObject.Create;
  var LCaminho := TJSONObject.Create;
  LCaminho.AddPair('type', 'string');
  LCaminho.AddPair('description', 'Caminho absoluto do arquivo .pas');
  LProps.AddPair('caminho', LCaminho);
  Result.Schema.InputSchema.AddPair('properties', LProps);
  Result.Schema.InputSchema.AddPair('required', TJSONArray.Create.AddElement('caminho'));
  Result.Execute := ExecutarExplicarCodigo;
end;

end.
