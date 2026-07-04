---
title: MinusMessaging
description: Message bus multi-provider com retry, circuit breaker e sagas
sidebar_label: MinusMessaging
---

<span class="badge badge-pro">Pro</span>

# MinusMessaging

MinusMessaging é um barramento de mensagens multi-provider com suporte a retry, circuit breaker, sagas e outbox pattern.

## Recursos

- **Providers:** RabbitMQ, Redis Pub/Sub, Kafka (via extensão)
- **Retry** — retry com backoff exponencial
- **Circuit Breaker** — proteção contra falhas em cascata
- **Sagas** — orquestração de transações distribuídas
- **Outbox Pattern** — garantia de entrega com o banco de dados

## Exemplo: Publicar mensagem

```pascal
var
  Bus: IMessageBus;
begin
  Bus := TMessageBus.Create(TRabbitMQProvider.Create('amqp://localhost'));
  Bus.Publish('pedidos.criados', TJSONObject.Create.AddPair('id', '123'));
end;
```

## Licenciamento

Disponível nos planos **Pro** e **Enterprise**.
