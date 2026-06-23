# Troubleshooting

## Compilação

### `E2280 Unterminated conditional directive`

**Causa:** IDE corrompida após crash (Access Violation em `coreide290.bpl`).

**Solução:**
1. Fechar Delphi completamente
2. Verificar se `bds.exe` não ficou rodando (Gerenciador de Tarefas)
3. Remover arquivos `.bpl` lockados:
   ```powershell
   Remove-Item "C:\Users\Public\Documents\Embarcadero\Studio\23.0\Bpl\*.bpl" -Force
   ```
4. Reabrir Delphi, fazer **Project → Clean** em cada pacote
5. Buildar novamente pelo `.groupproj`

### Access Violation ao abrir projeto

**Causa:** Bug conhecido do Delphi 11.

**Solução:**
1. Fechar IDE
2. Deletar `.dproj.local` e `.identcache` do projeto
3. Reabrir

## Execução

### "Database not available" nos testes

**Causa:** Bancos externos (Firebird, PostgreSQL, MySQL, MariaDB) não estão rodando.

**Solução:** Subir Docker:
```powershell
docker compose up -d
```

### Janela do teste fecha imediatamente

**Causa:** Applicação console finaliza após execução.

**Solução:** Adicionar `ReadLn;` no final do `.dpr` ou executar pelo terminal.

## Docker

### "failed to connect to the docker API"

**Causa:** Docker Desktop não está rodando.

**Solução:**
1. Abrir Docker Desktop
2. Aguardar inicialização
3. Configurar para iniciar com Windows: **Settings → General → Start Docker Desktop when you log in**

## Mensageria

### Conexão Redis recusada

**Causa:** Redis não está rodando na porta 6379.

**Solução:** Adicionar ao `docker-compose.yml`:
```yaml
redis:
  image: redis:7-alpine
  ports: ["6379:6379"]
```
