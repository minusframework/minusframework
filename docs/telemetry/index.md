---
title: MinusTelemetry
description: Tracing e logging estruturado no padrão OpenTelemetry
sidebar_label: MinusTelemetry
---

<span class="badge badge-enterprise">Enterprise</span>

# MinusTelemetry

MinusTelemetry implementa tracing distribuído e logging estruturado seguindo o padrão **OpenTelemetry**.

## Recursos

- **Tracing** — spans aninhados com context propagation
- **Logging** — logs estruturados em JSON
- **Exporters** — console, arquivo, OTLP (OpenTelemetry Protocol)
- **Integração** — com MinusORM, MinusMessaging e MinusFeatureFlags

## Exemplo: Tracing

```pascal
var
  Tracer: ITracer;
  Span: ISpan;
begin
  Tracer := TTelemetry.CreateTracer('meu-servico');
  Span := Tracer.StartSpan('processar-pedido');
  try
    // ... lógica do negócio
    Span.SetAttribute('pedido_id', 12345);
  finally
    Span.EndSpan;
  end;
end;
```

## Licenciamento

Disponível apenas no plano **Enterprise**.
