# MinusTelemetry — Telemetria e Observabilidade

**Pacote:** `MinusTelemetry_Runtime.dpk`  
**Diretório:** `Source\Telemetry\`

Sistema inspirado no OpenTelemetry para tracing distribuído, logging estruturado e métricas.

---

## Arquitetura

```
Tracer → Spans (tags, eventos, erro)
          ↓
     SpanCollector → Exporter → Jaeger/Zipkin/OTLP
          ↓
     Logger → Appenders → Console/Arquivo/Sistema

MetricasManager → Contadores / Calibradores / Histogramas
```

---

## Tracing (`MF.Telemetry.pas`)

### Span

Unidade fundamental de tracing.

```pascal
var
  LSpan: ISpan;
begin
  LSpan := TTelemetry.Tracer.IniciarSpan('processar-pedido');
  LSpan.SetTag('pedido_id', 42);
  LSpan.SetTag('cliente', 'João');

  try
    ProcessarPedido;
    LSpan.Finalizar;
  except
    on E: Exception do
    begin
      LSpan.SetErro(E);
      LSpan.Finalizar;
    end;
  end;
end;
```

### Span Kinds

| Kind | Uso |
|------|-----|
| `skInternal` | Operação interna |
| `skServer` | Requisição recebida (ex: HTTP) |
| `skClient` | Requisição enviada (ex: DB, HTTP) |
| `skProducer` | Mensagem publicada |
| `skConsumer` | Mensagem consumida |

### Contexto W3C Trace Context

```pascal
// Extrair contexto de requisição HTTP
var
  LContexto: TW3CContext;
begin
  LContexto := TW3CContext.Parse(
    '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01');

  TTelemetry.Tracer.DefinirBagagem(LContexto);

  // Spans criados a partir daqui herdam trace_id e parent_span_id
end;
```

### Atributos Adicionais

```pascal
LSpan.SetErro(Exception);
LSpan.AdicionarEvento('cache.miss', TValue.From<string>('produto:42'));
```

---

## Logging (`MF.Telemetry.Logger.pas`)

### Níveis de Log

| Nível | Método | Uso |
|-------|--------|-----|
| `llDebug` | `Debug` | Informação detalhada de desenvolvimento |
| `llInfo` | `Info` | Informação geral de operação |
| `llWarn` | `Warn` | Aviso (algo inesperado, não crítico) |
| `llError` | `Error` | Erro recuperável |
| `llFatal` | `Fatal` | Erro fatal (aplicação vai cair) |

### Uso

```pascal
TTelemetryLogger.Info('Pedido %d processado com sucesso', [Pedido.Id]);
TTelemetryLogger.Error('Falha ao processar pedido %d: %s', [Pedido.Id, E.Message]);

// Com span ativo — o log é vinculado ao span
TTelemetryLogger.Warn('Estoque baixo para o produto %d', [Produto.Id]);
```

### Appenders

```pascal
// Console
TTelemetryLogger.AdicionarAppender(TConsoleAppender.Create);

// Arquivo
TTelemetryLogger.AdicionarAppender(
  TStreamAppender.Create('C:\Logs\app.log'));
```

Appenders customizados: implemente `ILogAppender`.

---

## Métricas (`MF.Telemetry.pas`)

### Tipos de Métrica

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `mtContador` | Valor monotônico crescente | Total de requisições |
| `mtCalibrador` | Valor que sobe e desce | Memória usada, conexões ativas |
| `mtHistograma` | Distribuição de valores | Latência de requisições |

### Uso

```pascal
// Contador
TTelemetry.Metricas.Contador('http.requests.total')
  .Adicionar(1, ['method:GET', 'route:/api/produtos']);

// Calibrador
TTelemetry.Metricas.Calibrador('db.connections.active')
  .Atualizar(ConexoesAtivas);

// Histograma
TTelemetry.Metricas.Histograma('http.request.duration_ms')
  .Registrar(TempoMs, ['route:/api/produtos']);
```

---

## Exporters (`MF.Telemetry.Exporter.pas`)

### Backends Suportados

| Backend | Descrição |
|---------|-----------|
| `ebJaeger` | Jaeger (via UDP/HTTP) |
| `ebZipkin` | Zipkin (via HTTP) |
| `ebOTLP` | OpenTelemetry Protocol (gRPC ou HTTP) |
| `ebOTLPgRPC` | OTLP via gRPC |

### Configuração

```pascal
var
  LConfig: TExporterConfig;
begin
  LConfig := TExporterConfig.Create;
  LConfig.Backend := ebJaeger;
  LConfig.Endpoint := 'http://localhost:14268/api/traces';
  LConfig.ServiceName := 'meu-servico';

  TTelemetrySpanCollector.Configurar(LConfig);
end;
```

### Funcionamento Interno

- Os spans são enfileirados em um buffer
- Uma thread de background faz o flush periódico (a cada 5s ou a cada 64 spans)
- Em caso de falha, os spans são re-enfileirados
