# MinusFeatureFlags — Sistema de Feature Flags

**Projetos:**
- `MinusFeatureFlags.dpr` — CLI
- `MinusFeatureFlagsAPI.dpr` — REST API

**Diretório:** `Source\FeatureFlags\`

Sistema completo de feature flags com rollout percentual, targeting por usuário/grupo, variantes (A/B testing), cache, webhooks e auditoria.

---

## Tipos de Flag

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `tfBooleano` | Liga/Desliga | `nova-tela-checkout` |
| `tfInteiro` | Valor numérico | `limite-maximo-itens` |
| `tfTexto` | Valor textual | `url-api-pagamentos` |
| `tfJSON` | Valor JSON complexo | `configuracao-recomendacao` |

## Tipos de Rollout

| Tipo | Descrição |
|------|-----------|
| `trGlobal` | Ativada para todos |
| `trPercentual` | Percentual aleatório de usuários |
| `trPorUsuario` | Usuários específicos |
| `trPorGrupo` | Grupos específicos (beta, admin) |
| `trPorAtributo` | Por atributo do contexto (ex: plano=enterprise) |
| `trAgendado` | Ativa/desativa em data/hora específica |

---

## CLI

```
MinusFeatureFlags.exe <comando> [opções]
```

### `list`
Lista todas as flags.
```
MinusFeatureFlags.exe list
MinusFeatureFlags.exe list --filter ativas
MinusFeatureFlags.exe list --format json
```

### `get`
Obtém o valor de uma flag.
```
MinusFeatureFlags.exe get nova-tela-checkout
```

### `set`
Define ou altera uma flag.
```
MinusFeatureFlags.exe set nova-tela-checkout --value true
MinusFeatureFlags.exe set limite-maximo --value 50 --type integer
MinusFeatureFlags.exe set flag-json --value '{"key":"val"}' --type json
```

### `test`
Testa a avaliação de uma flag.
```
MinusFeatureFlags.exe test nova-tela-checkout --user usuario123
MinusFeatureFlags.exe test flag-beta --group beta
```

### `variants`
Gerencia variantes (A/B testing).
```
MinusFeatureFlags.exe variants botao-compra --add A,B,C --weights 50,30,20
```

### `export` / `import`
Exporta/importa flags para JSON.
```
MinusFeatureFlags.exe export --file flags.json
MinusFeatureFlags.exe import --file flags.json
```

---

## REST API

### Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/flags` | Lista todas as flags |
| `GET` | `/flags/:name` | Obtém flag por nome |
| `POST` | `/flags` | Cria nova flag |
| `PUT` | `/flags/:name` | Atualiza flag |
| `DELETE` | `/flags/:name` | Remove flag |
| `POST` | `/flags/:name/evaluate` | Avalia flag com contexto |
| `POST` | `/flags/:name/rollout` | Define regras de rollout |
| `GET` | `/flags/:name/variants` | Gerencia variantes |
| `GET` | `/health` | Health check |
| `GET` | `/metrics` | Métricas de avaliação |
| `GET` | `/events` | SSE stream de mudanças |

### Autenticação

A API usa JWT para autenticação:

```bash
# Obter token
curl -X POST /auth -d '{"username":"admin","password":"admin123"}'
# Resposta: {"token":"eyJ..."}

# Usar token
curl -H "Authorization: Bearer eyJ..." /flags
```

### SSE (Server-Sent Events)

```bash
curl -N -H "Accept: text/event-stream" /events

# Eventos recebidos em tempo real:
# event: flag.updated
# data: {"name":"nova-tela-checkout","old":false,"new":true}
#
# event: flag.created
# data: {"name":"flag-beta","type":"boolean","value":true}
```

---

## SDK (`MF.FeatureFlags.SDK.pas`)

Consumir flags de uma aplicação remota:

```csharp
var
  LSDK: TFeatureFlagsSDK;
begin
  LSDK := TFeatureFlagsSDK.Create('http://localhost:9000', 'meu-token');

  // Avaliar flag booleana
  if LSDK.Estatus('nova-tela-checkout') then
    MostrarNovaTela;

  // Avaliar com contexto
  LContexto := TContextoFlag.Create;
  LContexto.UserId := 'usuario123';
  LContexto.Grupos := TArray<string>('beta');

  if LSDK.Estatus('flag-beta', LContexto) then
    MostrarFuncionalidadeBeta;

  // Obter variante (A/B testing)
  case LSDK.Variante('botao-compra', LContexto) of
    'A': MostrarBotaoVermelho;
    'B': MostrarBotaoVerde;
    'C': MostrarBotaoAzul;
  end;
end;
```

---

## Integração com ORM

As feature flags são integradas ao `TConfiguracaoORM`:

```pascal
// Verificar flag durante operações do ORM
if TConfiguracaoORM.FeatureFlags.Habilitada('novo-algoritmo-cache') then
  UsarNovoCache
else
  UsarCacheLegado;
```

## Providers

| Provider | Descrição |
|----------|-----------|
| `TProviderMemoria` | Flags em memória (testes) |
| `TProviderJSON` | Flags em arquivo JSON |
| `TProviderREST` | Cliente da REST API |
| `TProviderDatabase` | Flags em tabela no banco |

## Auditoria

Todas as mutações de flags são registradas com:
- Quem alterou
- Valor antes/depois (JSON)
- Timestamp

## Webhooks

Notificações HTTP para URLs externas quando flags mudam.
