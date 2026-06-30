# MinusTelemetry â€” Roadmap

> **Ãšltima atualizaÃ§Ã£o:** Junho/2026

## Fase 1: FundaÃ§Ã£o (ConcluÃ­da)

| Capacidade | Status |
|---|---|
| Tracing distribuÃ­do (W3C Trace Context) | OK |
| Export Jaeger, Zipkin, OTLP | OK |
| MÃ©tricas (Counter/Gauge/Histogram) | OK |
| Export Prometheus | OK |
| Logging estruturado JSON | OK |
| Background thread exporter | OK |
| Auto-instrumentaÃ§Ã£o ORM | OK |
| Auto-instrumentaÃ§Ã£o REST (Horse) | OK |
| Auto-instrumentaÃ§Ã£o Messaging | OK |
| Zero dependÃªncias externas | OK |

## Fase 2: Polimento (ConcluÃ­da)

| Tarefa | Status |
|---|---|
| Sampling configurÃ¡vel | OK |
| Resource Attributes | OK |
| Histograma completo | OK |
| Span Events | OK |
| Baggage Propagation | OK |
| gRPC OTLP Export | OK |
| SpanKind | OK |

## Planejado

- Exemplar (vincular mÃ©trica ao trace)
- Dashboard embutido (pÃ¡gina Horse com grÃ¡ficos)
- Health Check endpoint compatÃ­vel com K8s
