program MinusAI_MCP;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MCP.Server in 'Core\MCP.Server.pas',
  MCP.Types in 'Core\MCP.Types.pas',
  AI.ExplicarCodigo in 'Tools\AI.ExplicarCodigo.pas',
  AI.GerarEntidade in 'Tools\AI.GerarEntidade.pas',
  AI.CriarMigracao in 'Tools\AI.CriarMigracao.pas',
  AI.ExecutarConsulta in 'Tools\AI.ExecutarConsulta.pas';

var
  LServer: TMCServer;
begin
  LServer := TMCServer.Create;
  try
    LServer.RegisterTool(RegistrarExplicarCodigo);
    LServer.RegisterTool(RegistrarGerarEntidade);
    LServer.RegisterTool(RegistrarCriarMigracao);
    LServer.RegisterTool(RegistrarExecutarConsulta);

    LServer.Run;
  finally
    LServer.Free;
  end;
end.
