# MinusMessaging â€” Roadmap

> **Ãšltima atualizaÃ§Ã£o:** Junho/2026

## Fase 0: Core (ConcluÃ­da)

| Tarefa | Status |
|---|---|
| `IMensagem`, `IMensageria`, `IProvedorMensageria` â€” interfaces core | OK |
| `TMessageBus` â€” orquestrador com retry + DLQ | OK |
| `TProvedorMemoria` â€” fila em memÃ³ria com TThreadedQueue | OK |
| SerializaÃ§Ã£o JSON via RTTI | OK |
| Testes unitÃ¡rios do Core | OK |
| CLI `MinusMessaging_CLI.exe` | OK |
| DocumentaÃ§Ã£o tÃ©cnica da arquitetura | OK |

## Fase 1: Providers Reais (ConcluÃ­da)

| Tarefa | Status |
|---|---|
| `TProvedorRedis` â€” filas (BRPOP) + pub/sub + DLQ via ZSET | OK |
| `TProvedorRabbitMQ` â€” exchanges, bindings, Basic.Ack/Nack, DLX | OK |
| Outbox pattern com MinusORM | OK |
| IdempotÃªncia | OK |
| Health Check Messaging | OK |
| MÃ©tricas por fila | OK |
| RabbitMQ Publisher Confirms | OK |

## Fase 2: ResiliÃªncia (ConcluÃ­da)

| Tarefa | Status |
|---|---|
| Saga coreografia (event-driven) | OK |
| Saga orquestraÃ§Ã£o (ISaga com passos + compensaÃ§Ã£o) | OK |
| Circuit breaker (ICircuitBreaker com half-open) | OK |
| `TProvedorMQTT` â€” QoS 0/1/2, will, retain | OK (parcial) |
| RPC sÃ­ncrono (request/reply via CorrelationId) | OK |
| Dashboard REST via Horse | Pendente |
| DLQ com reenvio seletivo via API | Pendente |

## Fase 3: Escala (Planejado)

- `TProvedorKafka` â€” consumer groups, offset commit, batch
- Streaming SSE (Server-Sent Events)
- Tracer distribuÃ­do (W3C Trace Context + OpenTelemetry)
- `TProvedorNuvem` â€” bridge SQS / Azure Service Bus
- Benchmark pÃºblico vs concorrentes
- BPL Runtime + Design
- IDE Expert para RAD Studio
- GetIt Package

## IntegraÃ§Ãµes

| IntegraÃ§Ã£o | DescriÃ§Ã£o |
|---|---|
| MinusORM | Outbox, IdempotÃªncia, Saga estado |
| MinusFeatureFlags | Toggle de consumidores sem deploy |
| MinusMigrator | Schema das tabelas de mensageria |
