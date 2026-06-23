# MinusMessaging — Message Bus e Padrões de Mensageria

**Pacote:** `MinusMessaging_Runtime.dpk`  
**Diretório:** `Source\Messaging\`

Sistema de mensageria com pub/sub, filas, provedores (Redis, RabbitMQ, Kafka, MQTT), padrões de resiliência (saga, circuit breaker, outbox) e monitoramento.

---

## Arquitetura

```
IMensageria (interface principal)
    |
    +-- IProvedorMensageria (por provider)
    |       |
    |       +-- InMemory
    |       +-- Redis
    |       +-- RabbitMQ
    |       +-- MQTT
    |       +-- Kafka
    |
    +-- TFilaWorker (thread de consumo)
    |
    +-- Padrões
    |       +-- Saga (orquestrada / coreografia)
    |       +-- Circuit Breaker
    |       +-- RPC
    |
    +-- Confiabilidade
    |       +-- Retry (exponencial / jitter)
    |       +-- DLQ (dead-letter queue)
    |
    +-- Monitoramento
            +-- Health Check
            +-- Métricas
            +-- SSE
            +-- OpenTelemetry
```

---

## Core (`MF.Messaging.Core.pas`)

### Publicação e Consumo

```pascal
var
  LBus: IMensageria;
begin
  LBus := TMessageBus.Create(TProvedorInMemory.Create);

  // Publicar
  LBus.Publicar('pedidos.criado', TPedido.Create);

  // Consumir (callback)
  LBus.Consumir('pedidos.criado',
    procedure(AMsg: IMensagem)
    begin
      ProcessarPedido(AMsg.Corpo.AsType<TPedido>);
    end);

  // Registrar fila com configuração
  LBus.RegistrarFila('pedidos.pendentes', TFilaConfig.Create
    .TTL(300)                // 5 minutos
    .DLQAtivo(True)          // Dead-letter queue ativa
    .TentativasMaximas(3)    // 3 retries
    .TipoEntrega(tePeloMenosUma)
  );

  // Subscribe (pub/sub — todos os consumers recebem)
  LBus.Subscribe('eventos.usuario.logado', MeuHandler);
end;
```

### Mensagem

```pascal
// Estrutura de IMensagem:
// - Id: TGUID
// - Tipo: TTipoMensagem (evento, comando, documento)
// - Nome: string
// - Corpo: TValue
// - Cabecalhos: TDictionary<string, string>
// - Rastreio: string (W3C trace context)
// - CriadoEm: TDateTime
// - Tentativas: Integer
```

### Serialização

```pascal
// Formatos suportados
TFilaConfig.Create
  .FormatoSerializacao(fsJson);      // JSON (padrão)

// Serializador binário (mais compacto)
TFilaConfig.Create
  .FormatoSerializacao(fsBinario);
```

---

## Provedores

### InMemory (`MF.Messaging.Provider.InMemory.pas`)

Transporte em memória. Ideal para testes e desenvolvimento.

```pascal
LBus := TMessageBus.Create(TProvedorInMemory.Create);
```

### Redis (`MF.Messaging.Provider.Redis.pas`)

```pascal
var
  LProvider: IProvedorMensageria;
begin
  LProvider := TProvedorRedis.Create('localhost', 6379);
  LBus := TMessageBus.Create(LProvider);
end;
```

### RabbitMQ (`MF.Messaging.Provider.RabbitMQ.pas`)

```pascal
LProvider := TProvedorRabbitMQ.Create(
  THost.Create('localhost', 5672, 'guest', 'guest'));
```

### MQTT (`MF.Messaging.Provider.MQTT.pas`)

```pascal
LProvider := TProvedorMQTT.Create('localhost', 1883);
```

### Kafka (`MF.Messaging.Provider.Kafka.pas`)

```pascal
LProvider := TProvedorKafka.Create(['localhost:9092']);
```

---

## Padrões de Resiliência

### Saga (`MF.Messaging.Saga.pas`)

**Saga Orquestrada:**

```pascal
var
  LSaga: TSagaOrquestrador;
begin
  LSaga := TSagaOrquestrador.Create('pedido.checkout');

  LSaga.AdicionarEtapa(
    TSagaEtapa.Create(
      procedure(ACtx: ISagaContext)
      begin
        ReservarEstoque(ACtx.Obter<Integer>('produto_id'));
      end,
      procedure(ACtx: ISagaContext)
      begin
        LiberarEstoque(ACtx.Obter<Integer>('produto_id'));
      end
    ));

  LSaga.AdicionarEtapa(
    TSagaEtapa.Create(
      procedure(ACtx: ISagaContext)
      begin
        CobrarCartao(ACtx.Obter<Currency>('valor'));
      end,
      procedure(ACtx: ISagaContext)
      begin
        ReembolsarCartao(ACtx.Obter<Currency>('valor'));
      end
    ));

  LSaga.Executar;
end;
```

**Saga Coreografia** (event-driven):

```pascal
// Cada serviço reage a eventos e publica seus próprios eventos
// Nome do evento → Ação
// "pedido.criado"  → "estoque.reservado"
// "estoque.reservado" → "pagamento.processado"
// "pagamento.processado" → "pedido.confirmado"
```

### Circuit Breaker (`MF.Messaging.CircuitBreaker.pas`)

```pascal
var
  LCB: TCircuitBreaker;
begin
  LCB := TCircuitBreaker.Create;
  LCB.Limiar := 5;        // 5 falhas para abrir
  LCB.Timeout := 30000;   // 30s para half-open

  LCB.Executar(
    procedure begin
      PublicarMensagem(LMsg);
    end,
    procedure(E: Exception) begin
      // Fallback quando o circuito está aberto
      SalvarNaDLQ(LMsg);
    end
  );
end;
```

### RPC (`MF.Messaging.RPC.pas`)

Requisição/resposta sobre mensageria.

```csharp
// Servidor
LRPCServer := TRPCServer.Create(LBus);
LRPCServer.Registrar('calc.soma',
  function(ARequest: TValue): TValue
  begin
    var LArgs := ARequest.AsType<TArray<Integer>>;
    Result := LArgs[0] + LArgs[1];
  end);

// Cliente
LRPCClient := TRPCClient.Create(LBus);
LResultado := LRPCClient.Enviar('calc.soma', [10, 20]).AsInteger;
```

---

## Confiabilidade

### Retry Policies (`MF.Messaging.Reliability.pas`)

```pascal
// Backoff fixo: 1s entre tentativas
TPoliticaBackoff(TBackoffFixo.Create(1000));

// Backoff exponencial: 1s, 2s, 4s, 8s...
TPoliticaBackoff(TBackoffExponencial.Create(1000, 30000));

// Com jitter (evita thundering herd)
TPoliticaBackoff(TBackoffJitter.Create(1000, 30000));
```

### Dead-Letter Queue

```pascal
// Configurar DLQ por fila
LBus.RegistrarFila('pedidos', TFilaConfig.Create
  .DLQAtivo(True)
  .DLQNome('pedidos.dlq')
  .TentativasMaximas(5));

// Processar DLQ
for var LMsg in TGerenciadorDLQMemoria.Create.Mensagens('pedidos.dlq') do
  Reprocessar(LMsg);
```

---

## Outbox Pattern (`MF.Messaging.Outbox.pas`)

Garante que mensagens sejam publicadas apenas se a transação do banco for confirmada.

```pascal
// 1. Salvar mensagem na tabela OUTBOX dentro da transação
TRepositorioOutbox.Salvar(LMensagemOutbox);

// 2. Confirmar transação

// 3. O TProcessadorOutbox (background) publica as mensagens pendentes
//    e as remove após confirmação do broker
```

---

## Idempotência (`MF.Messaging.Idempotencia.pas`)

Previne processamento duplicado de mensagens.

```pascal
// Verifica se a mensagem já foi processada pelo ID
if not TProcessadorIdempotencia.JaProcessado(LMsg.Id) then
begin
  Processar(LMsg);
  TProcessadorIdempotencia.MarcarProcessado(LMsg.Id);
end;
```

---

## Monitoramento

### Health Check

```pascal
var
  LHC: TSaudeMensageria;
begin
  LHC := TSaudeMensageria.Create(LBus);
  LRelatorio := LHC.Verificar;
  // Dados: total de filas, mensagens pendentes, consumers ativos, etc.
end;
```

### Métricas

```csharp
// Taxa de publicação/consumo por fila
// Latência de entrega
// Taxa de erro
// Mensagens na DLQ
```

### OpenTelemetry

Tracing automático de publish/consume com contexto W3C propagado nos cabeçalhos das mensagens.
