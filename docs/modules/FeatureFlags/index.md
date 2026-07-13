---
title: "FeatureFlags"
---

<span class="badge badge-pro">Pro</span>

# MinusFeatureFlags

Feature flags (feature toggles) com suporte a targeting rules, A/B testing e REST API com SSE para atualização em tempo real.

## Recursos

- **Core engine** — `TProviderJSON` e `TProviderMemoria` para gerenciar flags
- **REST API** — `MinusFeatureFlagsAPI` para gerenciamento remoto
- **Targeting rules** — ativação condicional por usuário, grupo, percentual
- **A/B testing** — variantes com distribuição percentual
- **SSE** — atualização em tempo real via Server-Sent Events
- **Métricas** — persistência de eventos no banco de dados

## Exemplo

```pascal
var
  Flags: TMinusFeatureFlags;
begin
  Flags := TMinusFeatureFlags.Create(TProviderJSON.Create('flags.json'));
  if Flags.IsActive('novo-checkout') then
    MostrarNovoCheckout
  else
    MostrarCheckoutLegado;
end;
```

## Repositório

[minusframework-featureflags](https://github.com/GabrielFerreiraMendes/minusframework-featureflags)
