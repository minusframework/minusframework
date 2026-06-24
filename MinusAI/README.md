# MinusAI

**Agentes inteligentes e servidor MCP para o ecossistema MinusFrameWork.**

## Ferramentas MCP

| Ferramenta | Descrição |
|------------|-----------|
| `explicar_codigo` | Analisa um arquivo `.pas` e explica sua estrutura |
| `gerar_entidade` | Gera código ORM a partir de uma tabela |
| `criar_migracao` | Cria arquivo de migração |
| `executar_consulta` | Executa SQL contra um banco |

## Uso

```powershell
MinusAI_MCP.exe
```

O servidor lê requisições JSON-RPC 2.0 via **stdin** e responde via **stdout**.
