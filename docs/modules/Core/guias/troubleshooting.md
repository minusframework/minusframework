# Troubleshooting

## CompilaÃ§Ã£o

### `E2280 Unterminated conditional directive`

**Causa:** IDE corrompida apÃ³s crash (Access Violation em `coreide290.bpl`).

**SoluÃ§Ã£o:**
1. Fechar Delphi completamente
2. Verificar se `bds.exe` nÃ£o ficou rodando (Gerenciador de Tarefas)
3. Remover arquivos `.bpl` lockados:
   ```powershell
   Remove-Item "C:\Users\Public\Documents\Embarcadero\Studio\23.0\Bpl\*.bpl" -Force
   ```
4. Reabrir Delphi, fazer **Project â†’ Clean** em cada pacote
5. Buildar novamente pelo `.groupproj`

### Access Violation ao abrir projeto

**Causa:** Bug conhecido do Delphi 11.

**SoluÃ§Ã£o:**
1. Fechar IDE
2. Deletar `.dproj.local` e `.identcache` do projeto
3. Reabrir

## ExecuÃ§Ã£o

### "Database not available" nos testes

**Causa:** Bancos externos (Firebird, PostgreSQL, MySQL, MariaDB) nÃ£o estÃ£o rodando.

**SoluÃ§Ã£o:** Subir Docker:
```powershell
docker compose up -d
```

### Janela do teste fecha imediatamente

**Causa:** ApplicaÃ§Ã£o console finaliza apÃ³s execuÃ§Ã£o.

**SoluÃ§Ã£o:** Adicionar `ReadLn;` no final do `.dpr` ou executar pelo terminal.

## Docker

### "failed to connect to the docker API"

**Causa:** Docker Desktop nÃ£o estÃ¡ rodando.

**SoluÃ§Ã£o:**
1. Abrir Docker Desktop
2. Aguardar inicializaÃ§Ã£o
3. Configurar para iniciar com Windows: **Settings â†’ General â†’ Start Docker Desktop when you log in**

## Mensageria

### ConexÃ£o Redis recusada

**Causa:** Redis nÃ£o estÃ¡ rodando na porta 6379.

**SoluÃ§Ã£o:** Adicionar ao `docker-compose.yml`:
```yaml
redis:
  image: redis:7-alpine
  ports: ["6379:6379"]
```
