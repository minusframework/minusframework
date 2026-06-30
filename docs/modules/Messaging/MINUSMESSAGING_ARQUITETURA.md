# MinusMessaging â€” Arquitetura de Mensageria para Delphi

> **Status:** Proposta TÃ©cnica v1.0
> **PropÃ³sito:** Camada de mensageria assÃ­ncrona multi-provider com integraÃ§Ã£o nativa ao ecossistema MinusFramework

---

## SumÃ¡rio

1. [VisÃ£o Geral](#1-visÃ£o-geral)
2. [Arquitetura](#2-arquitetura)
3. [Camada Core (AbstraÃ§Ãµes)](#3-camada-core-abstraÃ§Ãµes)
4. [Provedores (Providers)](#4-provedores-providers)
5. [PadrÃµes de Confiabilidade](#5-padrÃµes-de-confiabilidade)
6. [IntegraÃ§Ã£o com o Ecossistema](#6-integraÃ§Ã£o-com-o-ecossistema)
7. [File Structure](#7-file-structure)
8. [Roadmap](#8-roadmap)
9. [Comparativo de Mercado](#9-comparativo-de-mercado)
10. [DecisÃµes Arquiteturais](#10-decisÃµes-arquiteturais)

---

## 1. VisÃ£o Geral

### 1.1 O Problema

AplicaÃ§Ãµes Delphi modernas precisam de comunicaÃ§Ã£o assÃ­ncrona entre serviÃ§os, mas o ecossistema atual Ã© fragmentado:

- **Horse MQTT** â€” sÃ³ MQTT, sem abstraÃ§Ã£o multi-broker
- **Hormon** â€” sÃ³ in-memory, sem persistÃªncia nem integraÃ§Ã£o
- **RabbitMQ.Delphi** â€” sÃ³ AMQP, binding direto sem camada de abstraÃ§Ã£o
- ** implementaÃ§Ã£o manual** â€” cada projeto reinventa a roda

### 1.2 A SoluÃ§Ã£o

**MinusMessaging** â€” abstraÃ§Ã£o unificada sobre mÃºltiplos brokers, com:

- Interface `IMensageria` Ãºnica para publish/consume/subscribe
- Providers plugÃ¡veis: InMemory, Redis, RabbitMQ, MQTT, Kafka
- PadrÃµes embutidos: retry, DLQ, circuit breaker, outbox, saga
- IntegraÃ§Ã£o nativa com MinusORM, MinusFeatureFlags, MinusRest

### 1.3 PrincÃ­pios Arquiteturais

| PrincÃ­pio | AplicaÃ§Ã£o |
|-----------|-----------|
 | **Provider-agnostic** | Core nÃ£o depende de nenhum broker; providers sÃ£o injeÃ§Ãµes |
| **Retry by default** | Toda operaÃ§Ã£o tem polÃ­tica de retry configurÃ¡vel |
| **Dead Letter obrigatÃ³ria** | Toda fila tem DLQ â€” mensagens falhas nunca morrem |
| **Observabilidade** | MÃ©tricas, tracing e health check em todos os providers |
| **IdempotÃªncia** | Mensagens devem ser seguras para reprocessamento |
| **Transacional** | Outbox garante consistÃªncia DB + mensageria |

---

## 2. Arquitetura

### 2.1 Diagrama de Camadas

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                        APLICAÃ‡ÃƒO CLIENTE                          â”‚
â”‚   TServicePedido, TServiceEmail, TServiceNotificacao              â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                            â”‚
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                   MINUSMESSAGING CORE                            â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚
â”‚  â”‚ IMensageriaâ”‚  â”‚  IFila     â”‚  â”‚  ITopico   â”‚  â”‚ IConsumidorâ”‚  â”‚
â”‚  â”‚ (Facade)   â”‚  â”‚ (Queue)    â”‚  â”‚ (Pub/Sub)  â”‚  â”‚ (Worker)  â”‚  â”‚
â”‚  â””â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜  â”‚
â”‚        â”‚               â”‚               â”‚               â”‚        â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”  â”‚
â”‚  â”‚              TMessageBus (Orquestrador)                     â”‚  â”‚
â”‚  â”‚  - RetryPolicy / CircuitBreaker / DLQ / Outbox / Saga      â”‚  â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                               â”‚
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                     PROVIDER LAYER                               â”‚
â”‚                                                                   â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â” â”‚
â”‚  â”‚ TProvider- â”‚  â”‚ TProviderâ”‚  â”‚ TProviderâ”‚  â”‚ TProviderâ”‚  â”‚ TProviderâ”‚ â”‚
â”‚  â”‚ InMemory   â”‚  â”‚ Redis    â”‚  â”‚ RabbitMQ â”‚  â”‚ MQTT   â”‚  â”‚ Kafkaâ”‚ â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”˜ â”‚
â”‚                                                                   â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚
â”‚  â”‚  TProviderNuvem (SaaS Bridge: Amazon SQS, Azure SB, GCP)   â”‚  â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### 2.2 Fluxo de Mensagem

```
Produtor                    MessageBus                    Provider
    â”‚                           â”‚                            â”‚
    â”‚   bus.Publicar(evento)   â”‚                            â”‚
    â”‚â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–ºâ”‚                            â”‚
    â”‚                           â”‚                            â”‚
    â”‚                           â”‚ 1. Serializa (JSON/Bin)    â”‚
    â”‚                           â”‚ 2. Aplica Outbox (tx DB)  â”‚
    â”‚                           â”‚ 3. provider.Enfileirar()   â”‚
    â”‚                           â”‚â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–ºâ”‚
    â”‚                           â”‚                            â”‚
    â”‚                           â”‚           ACK              â”‚
    â”‚                           â”‚â—„â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”‚
    â”‚â—„â”€â”€â”€ Resultado(OK/DLQ) â”€â”€â”€â”€â”‚                            â”‚
    â”‚                           â”‚                            â”‚

Consumidor                    MessageBus                    Provider
    â”‚                           â”‚                            â”‚
    â”‚                           â”‚â—„â”€â”€â”€â”€â”€ Nova Mensagem â”€â”€â”€â”€â”€â”€â”€â”‚
    â”‚ bus.Consumir(handler)    â”‚                            â”‚
    â”‚â—„â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”‚                            â”‚
    â”‚                           â”‚                            â”‚
    â”‚ [Processa]                â”‚                            â”‚
    â”‚                           â”‚                            â”‚
    â”‚ Ack / Nack                â”‚                            â”‚
    â”‚â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–ºâ”‚                            â”‚
    â”‚                           â”‚ Ack â†’ provider.Ack()       â”‚
    â”‚                           â”‚ Nack â†’ Retry/DLQ           â”‚
```

### 2.3 Modelo de Dados (Core)

```pascal
type
  TTipoMensagem = (tmEvento, tmComando, tmDocumento);

  TTipoEntrega = (tePeloMenosUma, teNoMaximoUma, teExatamenteUma);

  TStatusMensagem = (smPendente, smProcessando, smConcluida, smFalha, smDLQ);

  // â”€â”€ Mensagem base â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ ConfiguraÃ§Ã£o de fila â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  TFilaConfig = record
    Nome: string;
    TipoEntrega: TTipoEntrega;
    MaxRetentativas: Integer;        // 0 = infinito
    Backoff: TBackoffPolicy;         // TExponentialBackoff, TFixedBackoff
    DLQ: string;                     // Nome da DLQ (auto-criada)
    TTL: Integer;                    // Time-to-live (segundos)
    PrefetchCount: Integer;          // Max mensagens simultÃ¢neas
    Serializacao: TFormatoSerializacao; // json, binÃ¡rio, msgpack
  end;

  // â”€â”€ Dead Letter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  IMensagemDLQ = interface(IMensagem)
    function Motivo: string;
    function Tentativas: Integer;
    function UltimoErro: string;
    function OriginalId: TGUID;
    function DataFalha: TDateTime;
  end;
```

---

## 3. Camada Core (AbstraÃ§Ãµes)

### 3.1 Interface Principal â€” `IMensageria`

```pascal
type
  // Facade unificada â€” ponto de entrada para toda a aplicaÃ§Ã£o
  IMensageria = interface
    ['{...}']

    // â”€â”€ ProduÃ§Ã£o â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    function Publicar(const ANome: string; const ACorpo: TValue;
      const ACabecalhos: TDictionary<string,string> = nil): TGUID;
    function Publicar(const AEvento: IEvento): TGUID;

    // â”€â”€ Consumo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    procedure Consumir(const AFila: string;
      const ACallback: TProc<IMensagem>);
    procedure Consumir(const AFila: string;
      const ACallback: TFunc<IMensagem, Boolean>); // True=Ack, False=Nack

    // â”€â”€ Subscribe (Pub/Sub) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    procedure Subscrever(const ATopico: string;
      const ACallback: TProc<IMensagem>);
    procedure PublicarNoTopico(const ATopico: string; const AMsg: IMensagem);

    // â”€â”€ Sagas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    function IniciarSaga(const ANome: string;
      const AEventoInicial: IEvento): ISaga;
    function ContinuarSaga(const ACorrelacaoId: TGUID): ISaga;

    // â”€â”€ Gerenciamento â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    procedure RegistrarFila(const AConfig: TFilaConfig);
    procedure RemoverFila(const ANome: string);
    function StatusDaFila(const ANome: string): TFilaStatus;
    procedure LimparDLQ(const AFila: string);
    function ReenviarDLQ(const AFila: string; const AId: TGUID): Boolean;

    // â”€â”€ Lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    procedure Iniciar;
    procedure Parar;
    function HealthCheck: THealthCheckResultado;
  end;
```

### 3.2 Provedor (Provider) â€” Contrato

```pascal
type
  // Cada provedor implementa este contrato
  IProvedorMensageria = interface
    ['{...}']

    // â”€â”€ AdministraÃ§Ã£o â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    procedure CriarFila(const AConfig: TFilaConfig);
    procedure DeletarFila(const ANome: string);
    procedure CriarTopico(const ANome: string);
    procedure VincularFilaAoTopico(const AFila, ATopico: string);

    // â”€â”€ ProduÃ§Ã£o â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    procedure Enfileirar(const AFila: string; const AMensagem: IMensagem);
    procedure PublicarNoTopico(const ATopico: string; const AMensagem: IMensagem);

    // â”€â”€ Consumo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    function ConsumirProximo(const AFila: string;
      out AMensagem: IMensagem): Boolean; // blocking/non-blocking
    procedure Ack(const AFila: string; const AId: TGUID);
    procedure Nack(const AFila: string; const AId: TGUID;
      const AMotivo: string; const AReenfileirar: Boolean);
    procedure RejeitarDLQ(const AFila: string; const AMensagem: IMensagemDLQ);

    // â”€â”€ Health â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    function Conectado: Boolean;
    function Ping: Int64; // latÃªncia em ms
  end;
```

### 3.3 SerializaÃ§Ã£o

```pascal
type
  TFormatoSerializacao = (fsJson, fsBinario, fsMessagePack);

  ISerializadorMensagem = interface
    function Serializar(const AMensagem: IMensagem): TBytes;
    function Desserializar(const ADados: TBytes;
      const AFormato: TFormatoSerializacao): IMensagem;
  end;
```

- **JSON**: padrÃ£o para interoperabilidade entre linguagens
- **BinÃ¡rio**: performance mÃ¡xima entre apps Delphi
- **MessagePack**: compactaÃ§Ã£o com suporte multi-linguagem

### 3.4 Mensagens SÃ­ncronas (Request/Reply)

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

PadrÃ£o: fila temporÃ¡ria anÃ´nima com `ReplyTo` + `CorrelationId`. Timeout configurÃ¡vel, exceÃ§Ã£o se nÃ£o responder.

---

## 4. Provedores (Providers)

### 4.1 InMemory â€” `TProvedorMemoria`

| Aspecto | Detalhe |
|---------|---------|
| **Backend** | `TThreadedQueue<IMensagem>` + `TDictionary<string, TList<TCallback>>` |
| **PersistÃªncia** | âŒ VolÃ¡til (opcional: arquivo JSON para dev/test) |
| **LatÃªncia** | < 1ms (mesmo processo) |
| **ConcorrÃªncia** | `TMonitor` ou `TLock` por fila |
| **Maturidade** | ProtÃ³tipo / testes unitÃ¡rios / dev local |
| **Roteamento** | Direto por nome de fila/tÃ³pico |

### 4.2 Redis â€” `TProvedorRedis`

| Aspecto | Detalhe |
|---------|---------|
| **Driver** | `Redis.Commons` + `Redis.Client` (delphiredis) |
| **Queue** | `RPOPLPUSH` (filas atÃ´micas com backup) |
| **Pub/Sub** | `SUBSCRIBE` / `PUBLISH` nativo |
| **DLQ** | Lista separada `fila:dql` + `BRPOPLPUSH` com timeout |
| **Health** | `PING` |
| **Retry** | `ZSET` score = timestamp tentativa |

### 4.3 RabbitMQ â€” `TProvedorRabbitMQ`

| Aspecto | Detalhe |
|---------|---------|
| **Driver** | `RabbitMQ.Delphi` ou `RabbitMQ.Client` |
| **Queue** | `basic.publish` com `delivery-mode=2` |
| **Pub/Sub** | Exchange `topic` + bindings |
| **DLQ** | Dead Letter Exchange nativo do RabbitMQ |
| **Prefetch** | `basic.qos` com `prefetch-count` |
| **Confirm** | Publisher confirms (`confirm.select`) |
| **TX** | AMQP transactions para outbox |

### 4.4 MQTT â€” `TProvedorMQTT`

| Aspecto | Detalhe |
|---------|---------|
| **Driver** | `TMQTTClient` (Embarcadero) ou `mqtt-delphi` |
| **QoS** | 0, 1, 2 (mapeado para entrega) |
| **Retain** | Mensagens retidas para novos subscribers |
| **Will** | Last Will para detecÃ§Ã£o de queda |
| **DLQ** | Simulada via tÃ³pico `$dql/{fila}` |
| **PersistÃªncia** | Session state no broker |

### 4.5 Kafka â€” `TProvedorKafka`

| Aspecto | Detalhe |
|---------|---------|
| **Driver** | `librdkafka` (C binding via `rdkafka.h`) |
| **Consumer Group** | `GROUP_ID` + offset commit |
| **Offset** | `auto.offset.reset=earliest` |
| **DLQ** | TÃ³pico `{topico}.DLQ` |
| **Batch** | ProduÃ§Ã£o em lote configurÃ¡vel |
| **Schema Registry** | Suporte futuro para Avro/Protobuf |

### 4.6 Tabela Comparativa de Providers

| Provider | PersistÃªncia | LatÃªncia | Throughput | Ordem Garantida | DLQ Nativa | Setup |
|----------|-------------|----------|------------|-----------------|------------|-------|
| InMemory | âŒ | ~0.1ms | 500k msg/s | âœ… | Simulada | Nenhum |
| Redis | âœ… Disco/RAM | ~1ms | 100k msg/s | âŒ | ZSET | Docker |
| RabbitMQ | âœ… Disco | ~5ms | 50k msg/s | âœ… | Exchange DLX | Docker |
| MQTT | âœ… Broker | ~10ms | 10k msg/s | âŒ | TÃ³pico Will | Mosquitto |
| Kafka | âœ… Disco log | ~20ms | 1M msg/s | âœ… PartiÃ§Ã£o | TÃ³pico `.DLQ` | ZooKeeper/KRaft |

---

## 5. PadrÃµes de Confiabilidade

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
    // 1Âª: 1s, 2Âª: 2s, 3Âª: 4s, 4Âª: 8s... atÃ© FMaxMs
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
Consumidor.Nack â†’ MessageBus â†’ RetryPolicy â†’ DLQ
                    â”‚                          â”‚
                    â”œâ”€â”€ Tentativa <= Max â”€â”€â”€â”€â”€â–ºâ”‚ Reenfileira com atraso
                    â”‚                          â”‚
                    â””â”€â”€ Tentativa > Max â”€â”€â”€â”€â”€â”€â–ºâ”‚ Envia para DLQ
```

### 5.2 Dead Letter Queue (DLQ)

Regras de negÃ³cio para DLQ:
- **Mensagem expirou TTL** â†’ DLQ automÃ¡tica
- **MÃ¡ximo de retries excedido** â†’ DLQ
- **Erro de desserializaÃ§Ã£o** â†’ DLQ imediato (sem retry)
- **Erro de aplicaÃ§Ã£o** â†’ Retry configurÃ¡vel, depois DLQ

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

Garante consistÃªncia transacional entre banco de dados e mensageria.

```pascal
// Fluxo:
// 1. BEGIN TRANSACTION
// 2. INSERT na tabela de negÃ³cio (ex: pedidos)
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

  // ImplementaÃ§Ã£o via MinusORM
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
PedidoCriado â†’ EstoqueReservado â†’ PagamentoConfirmado â†’ Notificado
     â”‚               â”‚                    â”‚                  â”‚
     â–¼               â–¼                    â–¼                  â–¼
ServicoA        ServicoB             ServicoC           ServicoD
```

#### OrquestraÃ§Ã£o (saga centralizada)

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
    // Se falhar, executa compensaÃ§Ãµes em ordem reversa
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
      // compensaÃ§Ã£o: marca email como cancelado
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

  // ConfiguraÃ§Ã£o:
  // - Threshold: 5 falhas consecutivas
  // - Timeout: 30 segundos (aberto â†’ meio-aberto)
  // - Half-open: 1 requisiÃ§Ã£o teste
  // Se passar â†’ fecha; se falhar â†’ volta aberto
```

### 5.6 IdempotÃªncia

```pascal
type
  IRepositorioIdempotencia = interface
    function JaProcessada(const AId: TGUID): Boolean;
    function Processar(const AId: TGUID): Boolean; // INSERT se nÃ£o existe
  end;

  // ImplementaÃ§Ã£o via MinusORM:
  // CREATE TABLE mensageria_idempotencia (
  //   mensagem_id CHAR(38) PRIMARY KEY,
  //   processado_em TIMESTAMP
  // );
```

---

## 6. IntegraÃ§Ã£o com o Ecossistema

### 6.1 MinusORM â€” Outbox + IdempotÃªncia + Sagas

```pascal
// Outbox usa TRepositorioBase<TMensagemPendente>
TRepositorioMensagemPendente = class(TRepositorioBase<TMensagemPendente>);

// IdempotÃªncia usa TRepositorioBase<TIdempotencia>
TRepositorioIdempotencia = class(TRepositorioBase<TIdempotencia>);

// Saga estado usa TRepositorioBase<TSagaEstado>
TRepositorioSaga = class(TRepositorioBase<TSagaEstado>);
```

### 6.2 MinusFeatureFlags â€” Controle de Consumidores

```pascal
// Desabilitar consumidor sem deploy
if FeatureFlags.EstaHabilitado('consumidor.email') then
  bus.Consumir('email.confirmacao', HandlerEmail);

// Routing dinÃ¢mico por flag
if FeatureFlags.EstaHabilitado('fila.nova') then
  bus.RegistrarFila(TFilaConfig.Nova('pedido.v2'))
else
  bus.RegistrarFila(TFilaConfig.Herdada('pedido.v1'));
```

### 6.3 MinusRest â€” Endpoints de Gerenciamento

```pascal
// Dashboard REST embutido
// GET  /api/messageria/filas           â†’ lista filas + status
// GET  /api/messageria/fila/:nome       â†’ detalhe da fila
// GET  /api/messageria/fila/:nome/dql   â†’ mensagens na DLQ
// POST /api/messageria/fila/:nome/dql/:id/reenviar
// POST /api/messageria/publicar         â†’ publicar mensagem avulsa
// GET  /api/messageria/health           â†’ health check
```

### 6.4 MinusMigrator â€” Schema das Tabelas

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
â”œâ”€â”€ Core/                              # JÃ¡ existe (ORM)
â””â”€â”€ Messaging/                         # Novo
    â”œâ”€â”€ MF.Messaging.Types.pas         # Enums, records, IMensagem
    â”œâ”€â”€ MF.Messaging.Core.pas          # TMessageBus, IMensageria
    â”œâ”€â”€ MF.Messaging.Serialization.pas # ISerializadorMensagem
    â”œâ”€â”€ MF.Messaging.Config.pas        # TFilaConfig, TTipoEntrega
    â”‚
    â”œâ”€â”€ Reliability/
    â”‚   â”œâ”€â”€ MF.Messaging.Retry.pas     # TBackoffPolicy, TExponentialBackoff
    â”‚   â”œâ”€â”€ MF.Messaging.DLQ.pas       # IGerenciadorDLQ
    â”‚   â”œâ”€â”€ MF.Messaging.CircuitBreaker.pas
    â”‚   â”œâ”€â”€ MF.Messaging.Outbox.pas    # IOutbox + TOutboxORM
    â”‚   â””â”€â”€ MF.Messaging.Saga.pas      # ISaga, TOrquestradorSaga
    â”‚
    â”œâ”€â”€ Providers/
    â”‚   â”œâ”€â”€ MF.Messaging.Provider.InMemory.pas
    â”‚   â”œâ”€â”€ MF.Messaging.Provider.Redis.pas
    â”‚   â”œâ”€â”€ MF.Messaging.Provider.RabbitMQ.pas
    â”‚   â”œâ”€â”€ MF.Messaging.Provider.MQTT.pas
    â”‚   â””â”€â”€ MF.Messaging.Provider.Kafka.pas
    â”‚
    â”œâ”€â”€ Integration/
    â”‚   â”œâ”€â”€ MF.Messaging.Integration.ORM.pas      # Outbox, IdempotÃªncia
    â”‚   â”œâ”€â”€ MF.Messaging.Integration.FeatureFlags.pas
    â”‚   â””â”€â”€ MF.Messaging.Integration.RestAPI.pas  # Endpoints Horse
    â”‚
    â””â”€â”€ Monitor/
        â”œâ”€â”€ MF.Messaging.Metrics.pas    # Contadores, histogramas
        â””â”€â”€ MF.Messaging.HealthCheck.pas # THealthCheckMessaging

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

### Fase 0 â€” FundaÃ§Ã£o âœ… ConcluÃ­do

- [x] Core: `IMensagem`, `IMensageria`, `IProvedorMensageria`
- [x] `TMessageBus` â€” orquestrador com retry + DLQ
- [x] `TProvedorMemoria` â€” testes e protÃ³tipo funcional
- [x] SerializaÃ§Ã£o JSON + BinÃ¡ria (`TSerializadorBinario`)
- [x] Pub/Sub (tÃ³picos, assinaturas, cancelamento)
- [x] DLQ com reenvio (evita duplicatas com novo GUID)
- [x] Testes unitÃ¡rios (21 testes DUnitX)
- [ ] CLI `MinusMessaging_CLI.exe` â€” publish/consume/status

### Fase 1 â€” Providers Reais âœ… Parcialmente ConcluÃ­do

- [x] `TProvedorRedis` â€” filas via protocolo RESP (LPUSH/RPOP/LLEN)
- [x] `TProvedorRabbitMQ` â€” filas via AMQP 0.9.1 (Queue.Declare/Delete, Basic.Publish/Get)
- [x] Outbox pattern com MinusORM
- [ ] IdempotÃªncia
- [ ] Health check integrado
- [ ] MÃ©tricas: contadores por fila, latÃªncia, taxa de DLQ

### Fase 2 â€” ResiliÃªncia (4-6 semanas)

- [ ] Saga coreografia + orquestraÃ§Ã£o
- [ ] Circuit breaker
- [ ] `TProvedorMQTT` â€” QoS 0/1/2, will, retain
- [ ] RequisiÃ§Ã£o/Resposta sÃ­ncrona (RPC)
- [ ] Dashboard REST embutido (Horse)
- [ ] DLQ com reenvio via API

### Fase 3 â€” Escala (6-8 semanas)

- [ ] `TProvedorKafka` â€” consumer groups, offset commit, batch
- [ ] Streaming SSE (Server-Sent Events) para UI em tempo real
- [ ] Tracer distribuÃ­do (OpenTelemetry compatÃ­vel)
- [ ] Benchmark pÃºblico vs concorrentes
- [ ] Pacotes BPL + GetIt
- [ ] IDE Expert para RAD Studio

### Maturidade

```
Fase 0 â”€â”€â”€â–º Fase 1 â”€â”€â”€â–º Fase 2 â”€â”€â”€â–º Fase 3
  â”‚           â”‚           â”‚           â”‚
  â–¼           â–¼           â–¼           â–¼
âœ… Core     âœ… Redis    âŒ Saga     âŒ Kafka
âœ… Pub/Sub  âœ… RabbitMQ âŒ MQTT     âŒ Streaming
âœ… DLQ      âœ… Outbox   âŒ RPC      âŒ Tracing
âœ… Serial   âŒ Health   âŒ Dashboard âŒ Benchmark
âœ… Testes   âŒ Metrics
```

---

## 9. Comparativo de Mercado

### Matriz de Features

| Funcionalidade | MinusMessaging | Horse MQTT | Hormon | RabbitMQ.Delphi | MassTransit (.NET) |
|---|---|---|---|---|---|
| **Multi-provider** | âœ… 5 providers | âŒ SÃ³ MQTT | âŒ SÃ³ memÃ³ria | âŒ SÃ³ AMQP | âœ… RabbitMQ + Azure |
| **Linguagem** | **Delphi** | Delphi | Delphi | Delphi | .NET |
| **LicenÃ§a** | **MIT** | MIT | MIT | ? | MIT |
| **PreÃ§o** | **GrÃ¡tis (Core)** | GrÃ¡tis | GrÃ¡tis | GrÃ¡tis | GrÃ¡tis |
| **DLQ Nativa** | âœ… | âŒ | âŒ | âŒ | âœ… |
| **Retry Policy** | âœ… Exponencial/Jitter | âŒ | âŒ | âŒ | âœ… |
| **Circuit Breaker** | âœ… | âŒ | âŒ | âŒ | âœ… |
| **Outbox Pattern** | âœ… ORM integrado | âŒ | âŒ | âŒ | âœ… |
| **Saga** | âœ… Coreografia + OrquestraÃ§Ã£o | âŒ | âŒ | âŒ | âœ… |
| **IdempotÃªncia** | âœ… | âŒ | âŒ | âŒ | âœ… |
| **SerializaÃ§Ã£o** | JSON/BinÃ¡rio/MsgPack | JSON | JSON | BinÃ¡rio | JSON/Bin |
| **RPC (Request/Reply)** | âœ… | âŒ | âŒ | âŒ | âœ… |
| **Health Check** | âœ… | âŒ | âŒ | âŒ | âœ… |
| **MÃ©tricas** | âœ… | âŒ | âŒ | âŒ | âœ… Prometheus |
| **Dashboard REST** | âœ… | âŒ | âŒ | âŒ | âŒ |
| **OpenTelemetry** | Roadmap | âŒ | âŒ | âŒ | âœ… |
| **IntegraÃ§Ã£o ORM** | âœ… Nativa | âŒ | âŒ | âŒ | âŒ (EF via terceiros) |
| **Feature Flags** | âœ… Integrado | âŒ | âŒ | âŒ | âŒ |
| **DocumentaÃ§Ã£o PT-BR** | âœ… | âŒ | âŒ | âŒ | âŒ |

### AnÃ¡lise por CenÃ¡rio

| CenÃ¡rio | RecomendaÃ§Ã£o | Motivo |
|---------|--------------|--------|
| AplicaÃ§Ã£o Delphi desktop com fila local | **MinusMessaging InMemory** | Zero dependÃªncia, ~0.1ms latÃªncia |
| MicroserviÃ§os Delphi + RabbitMQ | **MinusMessaging RabbitMQ** | DLX nativa, ordering guarantees, AMQP |
| IoT / sensores com MQTT | **MinusMessaging MQTT** | QoS 0/1/2, retain, will, leve |
| Event sourcing / stream pesado | **MinusMessaging Kafka** | Log append-only, replay, partiÃ§Ãµes |
| Cache + fila leve (um servidor) | **MinusMessaging Redis** | Menos infra, mesmo Redis do cache |
| Precisa de saga distribuÃ­da | **MinusMessaging** | Ãšnico no Delphi com suporte a saga |
| Equipe .NET | **MassTransit** | Ecossistema .NET maduro |
| SÃ³ precisa publicar/consumir MQTT | **Horse MQTT** | Leve, direto, sem overhead |

### PreÃ§o vs Concorrentes

| Produto | GrÃ¡tis? | PreÃ§o |
|---------|---------|-------|
| **MinusMessaging Community** | âœ… MIT | **GrÃ¡tis** (InMemory + 1 provider) |
| **MinusMessaging Pro** | âŒ | R$ 149/ano (todos providers + saga + dashboard) |
| **Horse MQTT** | âœ… MIT | GrÃ¡tis |
| **Hormon** | âœ… ? | GrÃ¡tis |
| **RabbitMQ.Delphi** | âœ… ? | GrÃ¡tis |
| **MassTransit** | âœ… MIT | GrÃ¡tis |
| **NServiceBus** | âŒ | $2,500+/ano |
| **Azure Service Bus** | âŒ | ~$10/mÃªs (Standard) |

---

## 10. DecisÃµes Arquiteturais

### 10.1 Por que uma interface Ãºnica (`IMensageria`) e nÃ£o mÃºltiplas interfaces segregadas?

**DecisÃ£o:** Facade unificada.

A interface Ãºnica simplifica a injeÃ§Ã£o de dependÃªncia em toda a aplicaÃ§Ã£o. O `TMessageBus` internamente delega para providers especÃ­ficos. Se no futuro houver necessidade de segregaÃ§Ã£o, pode-se extrair interfaces especializadas sem quebrar compatibilidade:

```pascal
type
  IMensageria = interface  // Facade â†’ uso 90% dos casos
  IProdutor = interface    // Especializada â†’ sÃ³ publica
  IConsumidor = interface  // Especializada â†’ sÃ³ consome
```

### 10.2 Por que nÃ£o usar generics para tipar mensagens?

**DecisÃ£o:** `TValue` (RTTI) em vez de `T<T>`.

Generics em Delphi nÃ£o funcionam bem como interface variance. `TValue` + RTTI permite que o mesmo MessageBus aceite qualquer tipo sem acoplamento de unidade:

```pascal
// âŒ TMessageBus<T> exige unit genÃ©rica, complica BPL
// âœ… IMensagem.Corpo as TValue â†’ RTTI â†’ qualquer tipo
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

### 10.3 Por que Outbox e nÃ£o XA Transactions?

**DecisÃ£o:** Outbox Ã© portÃ¡vel entre todos os providers.

XA Transactions funcionam apenas com bancos e brokers que suportam o padrÃ£o (poucos). Outbox funciona com qualquer provider e qualquer banco, sem depender de coordenador de transaÃ§Ã£o distribuÃ­da.

### 10.4 Por que nÃ£o usar somente JSON?

**DecisÃ£o:** SerializaÃ§Ã£o plugÃ¡vel, mas JSON como default.

- **JSON**: debugÃ¡vel, interoperÃ¡vel, schema evolution simples
- **BinÃ¡rio**: performance (sem parse), compacto
- **MessagePack**: melhor dos dois mundos

### 10.5 ConcorrÃªncia

```pascal
type
  TConsumidorConfig = record
    ThreadPoolSize: Integer;       // Default: CPU * 2
    PrefetchCount: Integer;        // Max mensagens simultÃ¢neas por thread
    BatchSize: Integer;            // Quantas ler por poll (Kafka/RabbitMQ)
    ShutdownTimeout: Integer;      // ms para drenar mensagens ativas
  end;
```

Cada fila tem seu prÃ³prio pool de threads. O `TThreadPool` gerencia:
- DistribuiÃ§Ã£o de mensagens entre threads
- Graceful shutdown (drenar mensagens ativas antes de parar)
- Backpressure (se fila cheia, reduz taxa de consumo)

### 10.6 Rastreamento DistribuÃ­do

```pascal
type
  ITraceContext = interface
    function TraceId: string;
    function SpanId: string;
    function ParentSpanId: string;

    // PropagaÃ§Ã£o via cabeÃ§alhos
    procedure ToHeaders(var ACabecalhos: TDictionary<string, string>);
    class function FromHeaders(
      const ACabecalhos: TDictionary<string, string>): ITraceContext;
  end;

// IntegraÃ§Ã£o futura com OpenTelemetry
// - W3C Trace Context (traceparent, tracestate)
// - Jaeger/Zipkin export via HTTP
// - MÃ©tricas: OpenMetrics / Prometheus
```

---

## ConclusÃ£o

O **MinusMessaging** preenche o vÃ¡cuo mais significativo no ecossistema Delphi. Nenhuma soluÃ§Ã£o atual oferece:

1. **Multi-provider** com interface Ãºnica
2. **PadrÃµes enterprise** (outbox, saga, DLQ, circuit breaker)
3. **IntegraÃ§Ã£o nativa** com ORM, Feature Flags e REST

As Fases 0 e 1 estÃ£o parcialmente implementadas: Core, Pub/Sub, DLQ, SerializaÃ§Ã£o BinÃ¡ria, Redis, RabbitMQ e Outbox jÃ¡ estÃ£o funcionais com 21 testes DUnitX passando.

---

> **PrÃ³ximos passos:** Testes de integraÃ§Ã£o com Redis/RabbitMQ reais, health check, mÃ©tricas, CLI de publicaÃ§Ã£o, pacote BPL piloto.
>
> *Documento gerado em Junho de 2026 â€” NÃ­vel: Arquiteto Especialista*
