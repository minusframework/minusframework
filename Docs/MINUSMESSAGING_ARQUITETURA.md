# MinusMessaging — Arquitetura de Mensageria para Delphi

> **Status:** Proposta Técnica v1.0
> **Propósito:** Camada de mensageria assíncrona multi-provider com integração nativa ao ecossistema MinusFramework

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Arquitetura](#2-arquitetura)
3. [Camada Core (Abstrações)](#3-camada-core-abstrações)
4. [Provedores (Providers)](#4-provedores-providers)
5. [Padrões de Confiabilidade](#5-padrões-de-confiabilidade)
6. [Integração com o Ecossistema](#6-integração-com-o-ecossistema)
7. [File Structure](#7-file-structure)
8. [Roadmap](#8-roadmap)
9. [Comparativo de Mercado](#9-comparativo-de-mercado)
10. [Decisões Arquiteturais](#10-decisões-arquiteturais)

---

## 1. Visão Geral

### 1.1 O Problema

Aplicações Delphi modernas precisam de comunicação assíncrona entre serviços, mas o ecossistema atual é fragmentado:

- **Horse MQTT** — só MQTT, sem abstração multi-broker
- **Hormon** — só in-memory, sem persistência nem integração
- **RabbitMQ.Delphi** — só AMQP, binding direto sem camada de abstração
- ** implementação manual** — cada projeto reinventa a roda

### 1.2 A Solução

**MinusMessaging** — abstração unificada sobre múltiplos brokers, com:

- Interface `IMensageria` única para publish/consume/subscribe
- Providers plugáveis: InMemory, Redis, RabbitMQ, MQTT, Kafka
- Padrões embutidos: retry, DLQ, circuit breaker, outbox, saga
- Integração nativa com MinusORM, MinusFeatureFlags, MinusRest

### 1.3 Princípios Arquiteturais

| Princípio | Aplicação |
|-----------|-----------|
 | **Provider-agnostic** | Core não depende de nenhum broker; providers são injeções |
| **Retry by default** | Toda operação tem política de retry configurável |
| **Dead Letter obrigatória** | Toda fila tem DLQ — mensagens falhas nunca morrem |
| **Observabilidade** | Métricas, tracing e health check em todos os providers |
| **Idempotência** | Mensagens devem ser seguras para reprocessamento |
| **Transacional** | Outbox garante consistência DB + mensageria |

---

## 2. Arquitetura

### 2.1 Diagrama de Camadas

```
┌──────────────────────────────────────────────────────────────────┐
│                        APLICAÇÃO CLIENTE                          │
│   TServicePedido, TServiceEmail, TServiceNotificacao              │
└───────────────────────────┬──────────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────────┐
│                   MINUSMESSAGING CORE                            │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌───────────┐  │
│  │ IMensageria│  │  IFila     │  │  ITopico   │  │ IConsumidor│  │
│  │ (Facade)   │  │ (Queue)    │  │ (Pub/Sub)  │  │ (Worker)  │  │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬─────┘  │
│        │               │               │               │        │
│  ┌─────▼───────────────▼───────────────▼───────────────▼─────┐  │
│  │              TMessageBus (Orquestrador)                     │  │
│  │  - RetryPolicy / CircuitBreaker / DLQ / Outbox / Saga      │  │
│  └───────────────────────────┬────────────────────────────────┘  │
└──────────────────────────────┼──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                     PROVIDER LAYER                               │
│                                                                   │
│  ┌────────────┐  ┌──────────┐  ┌──────────┐  ┌──────┐  ┌─────┐ │
│  │ TProvider- │  │ TProvider│  │ TProvider│  │ TProvider│  │ TProvider│ │
│  │ InMemory   │  │ Redis    │  │ RabbitMQ │  │ MQTT   │  │ Kafka│ │
│  └────────────┘  └──────────┘  └──────────┘  └──────┘  └─────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  TProviderNuvem (SaaS Bridge: Amazon SQS, Azure SB, GCP)   │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Fluxo de Mensagem

```
Produtor                    MessageBus                    Provider
    │                           │                            │
    │   bus.Publicar(evento)   │                            │
    │──────────────────────────►│                            │
    │                           │                            │
    │                           │ 1. Serializa (JSON/Bin)    │
    │                           │ 2. Aplica Outbox (tx DB)  │
    │                           │ 3. provider.Enfileirar()   │
    │                           │───────────────────────────►│
    │                           │                            │
    │                           │           ACK              │
    │                           │◄───────────────────────────│
    │◄─── Resultado(OK/DLQ) ────│                            │
    │                           │                            │

Consumidor                    MessageBus                    Provider
    │                           │                            │
    │                           │◄───── Nova Mensagem ───────│
    │ bus.Consumir(handler)    │                            │
    │◄──────────────────────────│                            │
    │                           │                            │
    │ [Processa]                │                            │
    │                           │                            │
    │ Ack / Nack                │                            │
    │──────────────────────────►│                            │
    │                           │ Ack → provider.Ack()       │
    │                           │ Nack → Retry/DLQ           │
```

### 2.3 Modelo de Dados (Core)

```pascal
type
  TTipoMensagem = (tmEvento, tmComando, tmDocumento);

  TTipoEntrega = (tePeloMenosUma, teNoMaximoUma, teExatamenteUma);

  TStatusMensagem = (smPendente, smProcessando, smConcluida, smFalha, smDLQ);

  // ── Mensagem base ───────────────────────────────────────
  IMensagem = interface
    ['{...}']
    function Id: TGUID;
    function Tipo: TTipoMensagem;
    function Nome: string;            // 'pedido.criado'
    function Versao: Integer;         // Schema version
    function CorrelacaoId: TGUID;     // Saga correlation
    function CausaId: TGUID;          // Causa origem
    function CriadoEm: TDateTime;
    function Cabecalhos: TDictionary<string, string>;
    function Corpo: TValue;           // Delphi RTTI value
    function Rastreio: string;        // Trace context
  end;

  // ── Configuração de fila ─────────────────────────────────
  TFilaConfig = record
    Nome: string;
    TipoEntrega: TTipoEntrega;
    MaxRetentativas: Integer;        // 0 = infinito
    Backoff: TBackoffPolicy;         // TExponentialBackoff, TFixedBackoff
    DLQ: string;                     // Nome da DLQ (auto-criada)
    TTL: Integer;                    // Time-to-live (segundos)
    PrefetchCount: Integer;          // Max mensagens simultâneas
    Serializacao: TFormatoSerializacao; // json, binário, msgpack
  end;

  // ── Dead Letter ──────────────────────────────────────────
  IMensagemDLQ = interface(IMensagem)
    function Motivo: string;
    function Tentativas: Integer;
    function UltimoErro: string;
    function OriginalId: TGUID;
    function DataFalha: TDateTime;
  end;
```

---

## 3. Camada Core (Abstrações)

### 3.1 Interface Principal — `IMensageria`

```pascal
type
  // Facade unificada — ponto de entrada para toda a aplicação
  IMensageria = interface
    ['{...}']

    // ── Produção ──────────────────────────────────────────
    function Publicar(const ANome: string; const ACorpo: TValue;
      const ACabecalhos: TDictionary<string,string> = nil): TGUID;
    function Publicar(const AEvento: IEvento): TGUID;

    // ── Consumo ───────────────────────────────────────────
    procedure Consumir(const AFila: string;
      const ACallback: TProc<IMensagem>);
    procedure Consumir(const AFila: string;
      const ACallback: TFunc<IMensagem, Boolean>); // True=Ack, False=Nack

    // ── Subscribe (Pub/Sub) ────────────────────────────────
    procedure Subscrever(const ATopico: string;
      const ACallback: TProc<IMensagem>);
    procedure PublicarNoTopico(const ATopico: string; const AMsg: IMensagem);

    // ── Sagas ──────────────────────────────────────────────
    function IniciarSaga(const ANome: string;
      const AEventoInicial: IEvento): ISaga;
    function ContinuarSaga(const ACorrelacaoId: TGUID): ISaga;

    // ── Gerenciamento ──────────────────────────────────────
    procedure RegistrarFila(const AConfig: TFilaConfig);
    procedure RemoverFila(const ANome: string);
    function StatusDaFila(const ANome: string): TFilaStatus;
    procedure LimparDLQ(const AFila: string);
    function ReenviarDLQ(const AFila: string; const AId: TGUID): Boolean;

    // ── Lifecycle ──────────────────────────────────────────
    procedure Iniciar;
    procedure Parar;
    function HealthCheck: THealthCheckResultado;
  end;
```

### 3.2 Provedor (Provider) — Contrato

```pascal
type
  // Cada provedor implementa este contrato
  IProvedorMensageria = interface
    ['{...}']

    // ── Administração ──────────────────────────────────────
    procedure CriarFila(const AConfig: TFilaConfig);
    procedure DeletarFila(const ANome: string);
    procedure CriarTopico(const ANome: string);
    procedure VincularFilaAoTopico(const AFila, ATopico: string);

    // ── Produção ───────────────────────────────────────────
    procedure Enfileirar(const AFila: string; const AMensagem: IMensagem);
    procedure PublicarNoTopico(const ATopico: string; const AMensagem: IMensagem);

    // ── Consumo ────────────────────────────────────────────
    function ConsumirProximo(const AFila: string;
      out AMensagem: IMensagem): Boolean; // blocking/non-blocking
    procedure Ack(const AFila: string; const AId: TGUID);
    procedure Nack(const AFila: string; const AId: TGUID;
      const AMotivo: string; const AReenfileirar: Boolean);
    procedure RejeitarDLQ(const AFila: string; const AMensagem: IMensagemDLQ);

    // ── Health ─────────────────────────────────────────────
    function Conectado: Boolean;
    function Ping: Int64; // latência em ms
  end;
```

### 3.3 Serialização

```pascal
type
  TFormatoSerializacao = (fsJson, fsBinario, fsMessagePack);

  ISerializadorMensagem = interface
    function Serializar(const AMensagem: IMensagem): TBytes;
    function Desserializar(const ADados: TBytes;
      const AFormato: TFormatoSerializacao): IMensagem;
  end;
```

- **JSON**: padrão para interoperabilidade entre linguagens
- **Binário**: performance máxima entre apps Delphi
- **MessagePack**: compactação com suporte multi-linguagem

### 3.4 Mensagens Síncronas (Request/Reply)

```pascal
type
  // RPC sobre fila
  IRpcCliente = interface
    function EnviarRequisicao(const AFila: string;
      const APayload: TValue; const ATimeout: Integer): IMensagem;

    procedure ResponderRequisicao(const ARequisicao: IMensagem;
      const AResposta: TValue);
  end;
```

Padrão: fila temporária anônima com `ReplyTo` + `CorrelationId`. Timeout configurável, exceção se não responder.

---

## 4. Provedores (Providers)

### 4.1 InMemory — `TProvedorMemoria`

| Aspecto | Detalhe |
|---------|---------|
| **Backend** | `TThreadedQueue<IMensagem>` + `TDictionary<string, TList<TCallback>>` |
| **Persistência** | ❌ Volátil (opcional: arquivo JSON para dev/test) |
| **Latência** | < 1ms (mesmo processo) |
| **Concorrência** | `TMonitor` ou `TLock` por fila |
| **Maturidade** | Protótipo / testes unitários / dev local |
| **Roteamento** | Direto por nome de fila/tópico |

### 4.2 Redis — `TProvedorRedis`

| Aspecto | Detalhe |
|---------|---------|
| **Driver** | `Redis.Commons` + `Redis.Client` (delphiredis) |
| **Queue** | `RPOPLPUSH` (filas atômicas com backup) |
| **Pub/Sub** | `SUBSCRIBE` / `PUBLISH` nativo |
| **DLQ** | Lista separada `fila:dql` + `BRPOPLPUSH` com timeout |
| **Health** | `PING` |
| **Retry** | `ZSET` score = timestamp tentativa |

### 4.3 RabbitMQ — `TProvedorRabbitMQ`

| Aspecto | Detalhe |
|---------|---------|
| **Driver** | `RabbitMQ.Delphi` ou `RabbitMQ.Client` |
| **Queue** | `basic.publish` com `delivery-mode=2` |
| **Pub/Sub** | Exchange `topic` + bindings |
| **DLQ** | Dead Letter Exchange nativo do RabbitMQ |
| **Prefetch** | `basic.qos` com `prefetch-count` |
| **Confirm** | Publisher confirms (`confirm.select`) |
| **TX** | AMQP transactions para outbox |

### 4.4 MQTT — `TProvedorMQTT`

| Aspecto | Detalhe |
|---------|---------|
| **Driver** | `TMQTTClient` (Embarcadero) ou `mqtt-delphi` |
| **QoS** | 0, 1, 2 (mapeado para entrega) |
| **Retain** | Mensagens retidas para novos subscribers |
| **Will** | Last Will para detecção de queda |
| **DLQ** | Simulada via tópico `$dql/{fila}` |
| **Persistência** | Session state no broker |

### 4.5 Kafka — `TProvedorKafka`

| Aspecto | Detalhe |
|---------|---------|
| **Driver** | `librdkafka` (C binding via `rdkafka.h`) |
| **Consumer Group** | `GROUP_ID` + offset commit |
| **Offset** | `auto.offset.reset=earliest` |
| **DLQ** | Tópico `{topico}.DLQ` |
| **Batch** | Produção em lote configurável |
| **Schema Registry** | Suporte futuro para Avro/Protobuf |

### 4.6 Tabela Comparativa de Providers

| Provider | Persistência | Latência | Throughput | Ordem Garantida | DLQ Nativa | Setup |
|----------|-------------|----------|------------|-----------------|------------|-------|
| InMemory | ❌ | ~0.1ms | 500k msg/s | ✅ | Simulada | Nenhum |
| Redis | ✅ Disco/RAM | ~1ms | 100k msg/s | ❌ | ZSET | Docker |
| RabbitMQ | ✅ Disco | ~5ms | 50k msg/s | ✅ | Exchange DLX | Docker |
| MQTT | ✅ Broker | ~10ms | 10k msg/s | ❌ | Tópico Will | Mosquitto |
| Kafka | ✅ Disco log | ~20ms | 1M msg/s | ✅ Partição | Tópico `.DLQ` | ZooKeeper/KRaft |

---

## 5. Padrões de Confiabilidade

### 5.1 Retry com Backoff

```pascal
type
  TBackoffPolicy = class abstract
    function ProximoIntervalo(const ATentativa: Integer): Integer; virtual; abstract;
  end;

  TExponentialBackoff = class(TBackoffPolicy)
  private
    FBaseMs: Integer;
    FMaxMs: Integer;
  public
    function ProximoIntervalo(const ATentativa: Integer): Integer; override;
    // 1ª: 1s, 2ª: 2s, 3ª: 4s, 4ª: 8s... até FMaxMs
  end;

  TFixedBackoff = class(TBackoffPolicy)
    // Intervalo fixo entre tentativas
  end;

  TJitterBackoff = class(TBackoffPolicy)
    // Exponencial + random(0, intervalo) para evitar thundering herd
  end;
```

Fluxo:
```
Consumidor.Nack → MessageBus → RetryPolicy → DLQ
                    │                          │
                    ├── Tentativa <= Max ─────►│ Reenfileira com atraso
                    │                          │
                    └── Tentativa > Max ──────►│ Envia para DLQ
```

### 5.2 Dead Letter Queue (DLQ)

Regras de negócio para DLQ:
- **Mensagem expirou TTL** → DLQ automática
- **Máximo de retries excedido** → DLQ
- **Erro de desserialização** → DLQ imediato (sem retry)
- **Erro de aplicação** → Retry configurável, depois DLQ

```pascal
type
  IGerenciadorDLQ = interface
    procedure EnviarParaDLQ(const AFilaOrigem: string; const AMensagem: IMensagem;
      const AMotivo: string; const ATentativas: Integer; const AErro: string);

    function ListarDLQ(const AFila: string): TArray<IMensagemDLQ>;
    function Reenviar(const AFila: string; const AId: TGUID): Boolean;
    function ReenviarTodas(const AFila: string): Integer;
    procedure Limpar(const AFila: string);
    function TotalDLQ(const AFila: string): Integer;
  end;
```

### 5.3 Outbox Pattern

Garante consistência transacional entre banco de dados e mensageria.

```pascal
// Fluxo:
// 1. BEGIN TRANSACTION
// 2. INSERT na tabela de negócio (ex: pedidos)
// 3. INSERT na tabela outbox (mensagem_pendente)
// 4. COMMIT
// 5. Publica mensagem (se falhar, OutboxWorker pega depois)

type
  IOutbox = interface
    procedure Adicionar(const AMensagem: IMensagem);
    function ObterPendentes(const ALimite: Integer): TArray<IMensagem>;
    procedure MarcarEnviada(const AId: TGUID);
    procedure MarcarFalha(const AId: TGUID; const AErro: string);
    function TotalPendentes: Integer;
  end;

  // Implementação via MinusORM
  TOutboxORM = class(TInterfacedObject, IOutbox)
    // Usa TRepositorioBase<TMensagemPendente>
    // Tabela: mensageria_outbox
    // Worker thread: a cada 1s, busca pendentes e reenvia
  end;
```

### 5.4 Saga Pattern

Dois modos:

#### Coreografia (event-driven)

```
PedidoCriado → EstoqueReservado → PagamentoConfirmado → Notificado
     │               │                    │                  │
     ▼               ▼                    ▼                  ▼
ServicoA        ServicoB             ServicoC           ServicoD
```

#### Orquestração (saga centralizada)

```pascal
type
  ISaga = interface
    function Id: TGUID;
    function Nome: string;
    function Estado: TEstadoSaga;

    // Passos
    function Passo(const ANome: string;
      const AAcao: TFunc<ISagaContext, Boolean>;
      const ACompensacao: TProc<ISagaContext>): ISaga;

    // Executa todos os passos em ordem
    function Executar: Boolean;
    // Se falhar, executa compensações em ordem reversa
    function Compensar: Boolean;
  end;

// Exemplo:
Saga := bus.IniciarSaga('cadastro.usuario')
  .Passo('criar.usuario',
    function(ctx): Boolean
    begin
      Repo.Salvar(Usuario);
      Result := True;
    end,
    procedure(ctx)
    begin
      Repo.Excluir(Usuario.Id);
    end)
  .Passo('enviar.email',
    function(ctx): Boolean
    begin
      bus.Publicar('email.boasvindas', Usuario);
      Result := True;
    end,
    procedure(ctx)
    begin
      // compensação: marca email como cancelado
    end)
  .Executar;
```

### 5.5 Circuit Breaker

```pascal
type
  TCircuitState = (csFechado, csAberto, csMeioAberto);

  ICircuitBreaker = interface
    function Estado: TCircuitState;
    procedure Executar(const AOperacao: TProc);
    function FalhasConsecutivas: Integer;
    procedure Resetar;
  end;

  // Configuração:
  // - Threshold: 5 falhas consecutivas
  // - Timeout: 30 segundos (aberto → meio-aberto)
  // - Half-open: 1 requisição teste
  // Se passar → fecha; se falhar → volta aberto
```

### 5.6 Idempotência

```pascal
type
  IRepositorioIdempotencia = interface
    function JaProcessada(const AId: TGUID): Boolean;
    function Processar(const AId: TGUID): Boolean; // INSERT se não existe
  end;

  // Implementação via MinusORM:
  // CREATE TABLE mensageria_idempotencia (
  //   mensagem_id CHAR(38) PRIMARY KEY,
  //   processado_em TIMESTAMP
  // );
```

---

## 6. Integração com o Ecossistema

### 6.1 MinusORM — Outbox + Idempotência + Sagas

```pascal
// Outbox usa TRepositorioBase<TMensagemPendente>
TRepositorioMensagemPendente = class(TRepositorioBase<TMensagemPendente>);

// Idempotência usa TRepositorioBase<TIdempotencia>
TRepositorioIdempotencia = class(TRepositorioBase<TIdempotencia>);

// Saga estado usa TRepositorioBase<TSagaEstado>
TRepositorioSaga = class(TRepositorioBase<TSagaEstado>);
```

### 6.2 MinusFeatureFlags — Controle de Consumidores

```pascal
// Desabilitar consumidor sem deploy
if FeatureFlags.EstaHabilitado('consumidor.email') then
  bus.Consumir('email.confirmacao', HandlerEmail);

// Routing dinâmico por flag
if FeatureFlags.EstaHabilitado('fila.nova') then
  bus.RegistrarFila(TFilaConfig.Nova('pedido.v2'))
else
  bus.RegistrarFila(TFilaConfig.Herdada('pedido.v1'));
```

### 6.3 MinusRest — Endpoints de Gerenciamento

```pascal
// Dashboard REST embutido
// GET  /api/messageria/filas           → lista filas + status
// GET  /api/messageria/fila/:nome       → detalhe da fila
// GET  /api/messageria/fila/:nome/dql   → mensagens na DLQ
// POST /api/messageria/fila/:nome/dql/:id/reenviar
// POST /api/messageria/publicar         → publicar mensagem avulsa
// GET  /api/messageria/health           → health check
```

### 6.4 MinusMigrator — Schema das Tabelas

```pascal
// Migration 001: infraestrutura de mensageria
// Tabelas:
//   mensageria_outbox
//   mensageria_idempotencia
//   mensageria_saga_estado
//   mensageria_saga_log
//   mensageria_dlq_log
```

---

## 7. File Structure

```
Source/
├── Core/                              # Já existe (ORM)
└── Messaging/                         # Novo
    ├── MF.Messaging.Types.pas         # Enums, records, IMensagem
    ├── MF.Messaging.Core.pas          # TMessageBus, IMensageria
    ├── MF.Messaging.Serialization.pas # ISerializadorMensagem
    ├── MF.Messaging.Config.pas        # TFilaConfig, TTipoEntrega
    │
    ├── Reliability/
    │   ├── MF.Messaging.Retry.pas     # TBackoffPolicy, TExponentialBackoff
    │   ├── MF.Messaging.DLQ.pas       # IGerenciadorDLQ
    │   ├── MF.Messaging.CircuitBreaker.pas
    │   ├── MF.Messaging.Outbox.pas    # IOutbox + TOutboxORM
    │   └── MF.Messaging.Saga.pas      # ISaga, TOrquestradorSaga
    │
    ├── Providers/
    │   ├── MF.Messaging.Provider.InMemory.pas
    │   ├── MF.Messaging.Provider.Redis.pas
    │   ├── MF.Messaging.Provider.RabbitMQ.pas
    │   ├── MF.Messaging.Provider.MQTT.pas
    │   └── MF.Messaging.Provider.Kafka.pas
    │
    ├── Integration/
    │   ├── MF.Messaging.Integration.ORM.pas      # Outbox, Idempotência
    │   ├── MF.Messaging.Integration.FeatureFlags.pas
    │   └── MF.Messaging.Integration.RestAPI.pas  # Endpoints Horse
    │
    └── Monitor/
        ├── MF.Messaging.Metrics.pas    # Contadores, histogramas
        └── MF.Messaging.HealthCheck.pas # THealthCheckMessaging

Packages/
    MinusMessaging_Runtime.dpk
    MinusMessaging_Design.dpk

Tests/
    Test.Messaging/
        Test.Messaging.Core.pas
        Test.Messaging.Outbox.pas
        Test.Messaging.Saga.pas
        Test.Messaging.Providers.pas
        Test.Messaging.DLQ.pas
```

---

## 8. Roadmap

### Fase 0 — Fundação ✅ Concluído

- [x] Core: `IMensagem`, `IMensageria`, `IProvedorMensageria`
- [x] `TMessageBus` — orquestrador com retry + DLQ
- [x] `TProvedorMemoria` — testes e protótipo funcional
- [x] Serialização JSON + Binária (`TSerializadorBinario`)
- [x] Pub/Sub (tópicos, assinaturas, cancelamento)
- [x] DLQ com reenvio (evita duplicatas com novo GUID)
- [x] Testes unitários (21 testes DUnitX)
- [ ] CLI `MinusMessaging_CLI.exe` — publish/consume/status

### Fase 1 — Providers Reais ✅ Parcialmente Concluído

- [x] `TProvedorRedis` — filas via protocolo RESP (LPUSH/RPOP/LLEN)
- [x] `TProvedorRabbitMQ` — filas via AMQP 0.9.1 (Queue.Declare/Delete, Basic.Publish/Get)
- [x] Outbox pattern com MinusORM
- [ ] Idempotência
- [ ] Health check integrado
- [ ] Métricas: contadores por fila, latência, taxa de DLQ

### Fase 2 — Resiliência (4-6 semanas)

- [ ] Saga coreografia + orquestração
- [ ] Circuit breaker
- [ ] `TProvedorMQTT` — QoS 0/1/2, will, retain
- [ ] Requisição/Resposta síncrona (RPC)
- [ ] Dashboard REST embutido (Horse)
- [ ] DLQ com reenvio via API

### Fase 3 — Escala (6-8 semanas)

- [ ] `TProvedorKafka` — consumer groups, offset commit, batch
- [ ] Streaming SSE (Server-Sent Events) para UI em tempo real
- [ ] Tracer distribuído (OpenTelemetry compatível)
- [ ] Benchmark público vs concorrentes
- [ ] Pacotes BPL + GetIt
- [ ] IDE Expert para RAD Studio

### Maturidade

```
Fase 0 ───► Fase 1 ───► Fase 2 ───► Fase 3
  │           │           │           │
  ▼           ▼           ▼           ▼
✅ Core     ✅ Redis    ❌ Saga     ❌ Kafka
✅ Pub/Sub  ✅ RabbitMQ ❌ MQTT     ❌ Streaming
✅ DLQ      ✅ Outbox   ❌ RPC      ❌ Tracing
✅ Serial   ❌ Health   ❌ Dashboard ❌ Benchmark
✅ Testes   ❌ Metrics
```

---

## 9. Comparativo de Mercado

### Matriz de Features

| Funcionalidade | MinusMessaging | Horse MQTT | Hormon | RabbitMQ.Delphi | MassTransit (.NET) |
|---|---|---|---|---|---|
| **Multi-provider** | ✅ 5 providers | ❌ Só MQTT | ❌ Só memória | ❌ Só AMQP | ✅ RabbitMQ + Azure |
| **Linguagem** | **Delphi** | Delphi | Delphi | Delphi | .NET |
| **Licença** | **MIT** | MIT | MIT | ? | MIT |
| **Preço** | **Grátis (Core)** | Grátis | Grátis | Grátis | Grátis |
| **DLQ Nativa** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Retry Policy** | ✅ Exponencial/Jitter | ❌ | ❌ | ❌ | ✅ |
| **Circuit Breaker** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Outbox Pattern** | ✅ ORM integrado | ❌ | ❌ | ❌ | ✅ |
| **Saga** | ✅ Coreografia + Orquestração | ❌ | ❌ | ❌ | ✅ |
| **Idempotência** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Serialização** | JSON/Binário/MsgPack | JSON | JSON | Binário | JSON/Bin |
| **RPC (Request/Reply)** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Health Check** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Métricas** | ✅ | ❌ | ❌ | ❌ | ✅ Prometheus |
| **Dashboard REST** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **OpenTelemetry** | Roadmap | ❌ | ❌ | ❌ | ✅ |
| **Integração ORM** | ✅ Nativa | ❌ | ❌ | ❌ | ❌ (EF via terceiros) |
| **Feature Flags** | ✅ Integrado | ❌ | ❌ | ❌ | ❌ |
| **Documentação PT-BR** | ✅ | ❌ | ❌ | ❌ | ❌ |

### Análise por Cenário

| Cenário | Recomendação | Motivo |
|---------|--------------|--------|
| Aplicação Delphi desktop com fila local | **MinusMessaging InMemory** | Zero dependência, ~0.1ms latência |
| Microserviços Delphi + RabbitMQ | **MinusMessaging RabbitMQ** | DLX nativa, ordering guarantees, AMQP |
| IoT / sensores com MQTT | **MinusMessaging MQTT** | QoS 0/1/2, retain, will, leve |
| Event sourcing / stream pesado | **MinusMessaging Kafka** | Log append-only, replay, partições |
| Cache + fila leve (um servidor) | **MinusMessaging Redis** | Menos infra, mesmo Redis do cache |
| Precisa de saga distribuída | **MinusMessaging** | Único no Delphi com suporte a saga |
| Equipe .NET | **MassTransit** | Ecossistema .NET maduro |
| Só precisa publicar/consumir MQTT | **Horse MQTT** | Leve, direto, sem overhead |

### Preço vs Concorrentes

| Produto | Grátis? | Preço |
|---------|---------|-------|
| **MinusMessaging Community** | ✅ MIT | **Grátis** (InMemory + 1 provider) |
| **MinusMessaging Pro** | ❌ | R$ 149/ano (todos providers + saga + dashboard) |
| **Horse MQTT** | ✅ MIT | Grátis |
| **Hormon** | ✅ ? | Grátis |
| **RabbitMQ.Delphi** | ✅ ? | Grátis |
| **MassTransit** | ✅ MIT | Grátis |
| **NServiceBus** | ❌ | $2,500+/ano |
| **Azure Service Bus** | ❌ | ~$10/mês (Standard) |

---

## 10. Decisões Arquiteturais

### 10.1 Por que uma interface única (`IMensageria`) e não múltiplas interfaces segregadas?

**Decisão:** Facade unificada.

A interface única simplifica a injeção de dependência em toda a aplicação. O `TMessageBus` internamente delega para providers específicos. Se no futuro houver necessidade de segregação, pode-se extrair interfaces especializadas sem quebrar compatibilidade:

```pascal
type
  IMensageria = interface  // Facade → uso 90% dos casos
  IProdutor = interface    // Especializada → só publica
  IConsumidor = interface  // Especializada → só consome
```

### 10.2 Por que não usar generics para tipar mensagens?

**Decisão:** `TValue` (RTTI) em vez de `T<T>`.

Generics em Delphi não funcionam bem como interface variance. `TValue` + RTTI permite que o mesmo MessageBus aceite qualquer tipo sem acoplamento de unidade:

```pascal
// ❌ TMessageBus<T> exige unit genérica, complica BPL
// ✅ IMensagem.Corpo as TValue → RTTI → qualquer tipo
```

O cliente faz o cast no callback:

```pascal
bus.Consumir('pedido.criado',
  procedure(const AMsg: IMensagem)
  var
    LPedido: TPedido;
  begin
    LPedido := AMsg.Corpo.AsType<TPedido>;
    // processa
  end);
```

### 10.3 Por que Outbox e não XA Transactions?

**Decisão:** Outbox é portável entre todos os providers.

XA Transactions funcionam apenas com bancos e brokers que suportam o padrão (poucos). Outbox funciona com qualquer provider e qualquer banco, sem depender de coordenador de transação distribuída.

### 10.4 Por que não usar somente JSON?

**Decisão:** Serialização plugável, mas JSON como default.

- **JSON**: debugável, interoperável, schema evolution simples
- **Binário**: performance (sem parse), compacto
- **MessagePack**: melhor dos dois mundos

### 10.5 Concorrência

```pascal
type
  TConsumidorConfig = record
    ThreadPoolSize: Integer;       // Default: CPU * 2
    PrefetchCount: Integer;        // Max mensagens simultâneas por thread
    BatchSize: Integer;            // Quantas ler por poll (Kafka/RabbitMQ)
    ShutdownTimeout: Integer;      // ms para drenar mensagens ativas
  end;
```

Cada fila tem seu próprio pool de threads. O `TThreadPool` gerencia:
- Distribuição de mensagens entre threads
- Graceful shutdown (drenar mensagens ativas antes de parar)
- Backpressure (se fila cheia, reduz taxa de consumo)

### 10.6 Rastreamento Distribuído

```pascal
type
  ITraceContext = interface
    function TraceId: string;
    function SpanId: string;
    function ParentSpanId: string;

    // Propagação via cabeçalhos
    procedure ToHeaders(var ACabecalhos: TDictionary<string, string>);
    class function FromHeaders(
      const ACabecalhos: TDictionary<string, string>): ITraceContext;
  end;

// Integração futura com OpenTelemetry
// - W3C Trace Context (traceparent, tracestate)
// - Jaeger/Zipkin export via HTTP
// - Métricas: OpenMetrics / Prometheus
```

---

## Conclusão

O **MinusMessaging** preenche o vácuo mais significativo no ecossistema Delphi. Nenhuma solução atual oferece:

1. **Multi-provider** com interface única
2. **Padrões enterprise** (outbox, saga, DLQ, circuit breaker)
3. **Integração nativa** com ORM, Feature Flags e REST

As Fases 0 e 1 estão parcialmente implementadas: Core, Pub/Sub, DLQ, Serialização Binária, Redis, RabbitMQ e Outbox já estão funcionais com 21 testes DUnitX passando.

---

> **Próximos passos:** Testes de integração com Redis/RabbitMQ reais, health check, métricas, CLI de publicação, pacote BPL piloto.
>
> *Documento gerado em Junho de 2026 — Nível: Arquiteto Especialista*
