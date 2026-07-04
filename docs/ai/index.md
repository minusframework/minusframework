---
title: MinusAI
description: Agentes inteligentes e servidor MCP para Delphi
sidebar_label: MinusAI
---

<span class="badge badge-enterprise">Enterprise</span>

# MinusAI

MinusAI fornece um servidor **MCP (Model Context Protocol)** e agentes inteligentes para aplicações Delphi.

## Recursos

- **Servidor MCP** — integração com LLMs via protocolo padronizado
- **Agentes** — execução de tarefas com chain-of-thought
- **Ferramentas** — expõe funções do seu sistema como tools para a IA

## Exemplo: Servidor MCP

```pascal
var
  MCPServer: TMinusMCPServer;
begin
  MCPServer := TMinusMCPServer.Create;
  try
    MCPServer.RegisterTool('buscar_cliente', 'Busca cliente por ID',
      procedure(const Args: TJSONObject; var Result: TJSONValue)
      begin
        Result := TJSONObject.Create;
        Result.AddPair('nome', 'João Silva');
      end);
    MCPServer.Start(8080);
    ReadLn;
  finally
    MCPServer.Free;
  end;
end;
```

## Licenciamento

Disponível apenas no plano **Enterprise**.
