# MinusMessaging — Guia de Uso

> **Versão:** 1.0
> **Última atualização:** Junho de 2026
> **Fase:** 0 (Core, InMemory, Serialização, DLQ, Redis, RabbitMQ, Pub/Sub, Outbox)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Instalação](#2-instalação)
3. [Primeiros Passos](#3-primeiros-passos)
4. [Filas (Queue)](#4-filas-queue)
5. [Pub/Sub (Tópicos)](#5-pubsub-tópicos)
6. [Serialização](#6-serialização)
7. [DLQ — Dead Letter Queue](#7-dlq--dead-letter-queue)
8. [Outbox Pattern](#8-outbox-pattern)
9. [Provedores](#9-provedores)
10. [Testes](#10-testes)

---

## 1. Visão Geral

**MinusMessaging** é o subsistema de mensageria assíncrona do MinusFramework. Ele provê uma interface única (`IMensageria`) que abstrai diferentes brokers (Redis, RabbitMQ, InMemory) e implementa padrões de confiabilidade como DLQ, retry e Outbox.

### Arquitetura

```
┌──────────────┐
│  TMessageBus │ ← Facade principal (pub/sub + filas)
├──────────────┤
│  IMensageria │ ← Interface do provider
├──────────────┤
│  InMemory    │ ← Provider padrão (testes/dev)
│  Redis       │ ← Provider via protocolo RESP
│  RabbitMQ    │ ← Provider via AMQP 0.9.1
└──────────────┘
```

---

## 2. Instalação

### 2.1 Packages

1. Abra `Packages\MinusMessaging_Runtime.dpk` no RAD Studio
2. Compile o package
3. Adicione ao Search Path:
   - `Source\Messaging`
   - `Source\Messaging\Reliability`
   - `Source\Messaging\Providers`

### 2.2 Dependências

- **IndySystem** e **IndyCore** — usados pelos provedores Redis e RabbitMQ
- **MF.ORM** — necessário apenas para o Outbox (pacote separado)

---

## 3. Primeiros Passos

### 3.1 Exemplo Mínimo

```pascal
uses
  MF.Messaging.Core,
  MF.Messaging.Provider.InMemory;

var
  LBus: TMessageBus;
  LProvider: IProvedorMensageria;
begin
  LBus := TMessageBus.Create;
  try
    LProvider := TProvedorMemoria.Create;
    LBus.RegistrarProvider('memoria', LProvider, True);

    LBus.Publicar('minha.fila', TValue.From('Olá Mundo!'));
  finally
    LBus.Free;
  end;
end;
```

### 3.2 Consumindo Mensagens

```pascal
LBus.RegistrarFila(TFilaConfig.Padrao('minha.fila'));
LBus.Publicar('minha.fila', TValue.From(42));

LBus.Consumir('minha.fila',
  procedure(const AMsg: IMensagem)
  begin
    WriteLn(Format('Recebido: %s', [AMsg.Corpo.ToString]));
  end);
```

---

## 4. Filas (Queue)

### 4.1 Publicar

```pascal
// Com corpo tipado
LBus.Publicar('pedidos.criados', TValue.From(12345));

// Com objeto
LBus.Publicar('pedidos.criados', TObject(MeuObjeto));

// Com mensagem personalizada
var LMsg: IMensagem := TMensagem.Create('pedido.cancelado', TValue.Empty);
LMsg.AdicionarCabecalho('motivo', 'estoque_insuficiente');
LMsg.CorrelacaoId := pedidoId;
LMsg.CausaId := eventoOriginalId;
LBus.Publicar(LMsg);
```

### 4.2 Consumir

```pascal
LBus.RegistrarFila(TFilaConfig.Padrao('minha.fila'));

// Callback com TProc<IMensagem>
LBus.Consumir('minha.fila',
  procedure(const AMsg: IMensagem)
  begin
    if AMsg.Tentativas > 3 then
      LBus.EnviarParaDLQ('minha.fila', AMsg, 'max_retry', 'Excedeu 3 tentativas');
  end);
```

### 4.3 Configuração de Fila

```pascal
var
  LConfig: TFilaConfig;
begin
  LConfig.Nome := 'pedidos.pendentes';
  LConfig.Provider := 'redis';
  LConfig.TimeoutMs := 5000;
  LConfig.MaxTentativas := 5;
  LBus.RegistrarFila(LConfig);
end;
```

---

## 5. Pub/Sub (Tópicos)

### 5.1 Publicar em Tópico

```pascal
LBus.PublicarNoTopico('eventos.usuario.logado',
  TValue.From('usuario_123'),
  TDictionary<string, string>.Create);
```

### 5.2 Subscrever

```pascal
var
  LSubId: string;
begin
  LSubId := LBus.Subscrever('eventos.usuario.logado',
    function(const AMsg: IMensagem): Boolean
    begin
      WriteLn('Usuário logou: ' + AMsg.Corpo.ToString);
      Result := True;
    end);
end;
```

### 5.3 Cancelar Subscrição

```pascal
LBus.CancelarSubscricao(LSubId);
// A partir de agora, o callback não será mais chamado
```

### 5.4 Múltiplos Assinantes

```pascal
// Ambos receberão a mensagem
LBus.Subscrever('eventos.usuario.logado', CallbackAdmin);
LBus.Subscrever('eventos.usuario.logado', CallbackAuditoria);
LBus.PublicarNoTopico('eventos.usuario.logado', TValue.From('usuario_456'));
```

---

## 6. Serialização

### 6.1 Serialização JSON

```pascal
var
  LJson: string;
  LMsg, LMsg2: IMensagem;
begin
  LMsg := TMensagem.Create('teste.evento', TValue.From(42));
  LMsg.AdicionarCabecalho('versao', '1.0');

  LJson := MensagemParaJson(LMsg);
  LMsg2 := JsonParaMensagem(LJson);  // preserva headers, ids, etc.
end;
```

### 6.2 Serialização Binária

```pascal
var
  LBytes: TBytes;
  LMsg, LMsg2: IMensagem;
begin
  LMsg := TMensagem.Create('teste.evento', TValue.From(42));
  LMsg.AdicionarCabecalho('versao', '1.0');

  LBytes := TSerializadorBinario.Serializar(LMsg);
  LMsg2 := TSerializadorBinario.Desserializar(LBytes);  // round-trip completo
end;
```

Formato binário:
| Campo | Tamanho |
|-------|---------|
| Version byte | 1 byte |
| Id (GUID) | 16 bytes |
| Tipo | 1 byte |
| Nome | length-prefixed UTF-8 |
| CriadoEm | 8 bytes (Double) |
| Tentativas | 4 bytes |
| CorrelationId | 16 bytes |
| CausationId | 16 bytes |
| Rastreio | length-prefixed UTF-8 |
| Headers | count + key-value pairs |

---

## 7. DLQ — Dead Letter Queue

### 7.1 Enviar para DLQ

```pascal
LDLQ.EnviarParaDLQ('fila.origem', AMensagem, 'erro_validacao', 'Campo obrigatório ausente');
```

### 7.2 Listar e Reenviar

```pascal
// Total de mensagens na DLQ
WriteLn(IntToStr(LDLQ.TotalDLQ('fila.origem')));

// Reenviar (gera novo GUID, evita duplicatas no destino)
if LDLQ.Reenviar('fila.origem', mensagemId) then
  WriteLn('Mensagem reenviada com sucesso');

// Limpar DLQ
LDLQ.Limpar('fila.origem');
```

---

## 8. Outbox Pattern

### 8.1 Conceito

O Outbox garante entrega confiável: em vez de publicar direto no broker, a mensagem é salva no banco (dentro da mesma transação da operação de negócio) e um worker background a publica assincronamente.

### 8.2 Configuração

```pascal
uses
  MF.Messaging.Integration.Outbox;

var
  LOutbox: TOutboxMiddleware;
  LRepositorio: TRepositorioOutbox;
begin
  LRepositorio := TRepositorioOutbox.Create(FConexao);
  LOutbox := TOutboxMiddleware.Create(LBus, LRepositorio);
  LOutbox.Iniciar;  // inicia o worker background
  // ...
  LOutbox.Parer;    // para o worker
end;
```

### 8.3 Hook OnAntesPublicar

O hook `OnAntesPublicar` no `TMessageBus` intercepta toda publicação. O Outbox usa este hook para capturar a mensagem antes do envio:

```pascal
LBus.OnAntesPublicar :=
  procedure(const AMsg: IMensagem)
  begin
    // Salva no banco dentro da transação atual
    Repositorio.Salvar(AMsg);
  end;
```

### 8.4 Tabela no Banco

```sql
CREATE TABLE messaging_outbox (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  mensagem_id CHAR(38) NOT NULL,
  fila VARCHAR(255) NOT NULL,
  corpo BLOB,
  cabecalhos TEXT,
  status INTEGER DEFAULT 0,  -- 0=pendente, 1=publicada, 2=falha
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  publicado_em TIMESTAMP,
  tentativas INTEGER DEFAULT 0,
  ultimo_erro VARCHAR(500)
);
```

---

## 9. Provedores

### 9.1 InMemory (Padrão)

Provider em memória para testes e desenvolvimento. Não persiste dados.

```pascal
LProvider := TProvedorMemoria.Create;
LBus.RegistrarProvider('memoria', LProvider, True);
```

### 9.2 Redis

Provider via protocolo RESP sobre TCP (Indy). Usa Redis Lists (`LPUSH`/`RPOP`).

```pascal
uses
  MF.Messaging.Provider.Redis;

var
  LProvider: IProvedorMensageria;
begin
  LProvider := TProvedorRedis.Create('localhost', 6379, 'senha_opcional');
  LBus.RegistrarProvider('redis', LProvider, True);
end;
```

Comandos utilizados: `PING`, `AUTH`, `LPUSH`, `RPOP`, `LLEN`, `DEL`.

### 9.3 RabbitMQ

Provider via protocolo AMQP 0.9.1 sobre TCP (Indy).

```pascal
uses
  MF.Messaging.Provider.RabbitMQ;

var
  LProvider: IProvedorMensageria;
begin
  LProvider := TProvedorRabbitMQ.Create('localhost', 5672, 'guest', 'guest', '/');
  LBus.RegistrarProvider('rabbit', LProvider, True);
end;
```

Operações: `Connection.Open`, `Channel.Open`, `Queue.Declare`/`Delete`, `Basic.Publish`/`Get`.

---

## 10. Testes

### 10.1 Executar Testes

O projeto `Tests\Test.Messaging\Test.MinusMessaging.dproj` contém 21 testes DUnitX:

| Fixture | Testes | Descrição |
|---------|--------|-----------|
| `TesteMensagem` | 4 | Criação, ID único, status, headers |
| `TesteMessageBus` | 4 | Publicar, consumir, fila direta, status |
| `TesteDLQ` | 5 | Enviar, total, reenviar, ID inexistente, limpar |
| `TesteSerializacaoBinaria` | 2 | Round-trip de dados e cabeçalhos |
| `TestePubSub` | 4 | Entrega, ID único, cancelamento, múltiplos |
| `TesteOutbox` | 2 | Callback OnAntesPublicar |

Execute pelo RAD Studio ou pelo runner:

```
Test.MinusMessaging.exe
Test.MinusMessaging.exe --xml:resultados.xml   # saída JUnit
```

---

## Referência Rápida

### Interfaces

| Interface | Descrição |
|-----------|-----------|
| `IMensagem` | Mensagem individual (Id, Nome, Corpo, Headers, etc.) |
| `IProvedorMensageria` | Provider (InMemory, Redis, RabbitMQ) |
| `IMensageria` | Facade principal (Publicar, Consumir, Subscrever) |
| `IGerenciadorDLQ` | DLQ (EnviarParaDLQ, Reenviar, Limpar) |

### Classes Core

| Classe | Descrição |
|--------|-----------|
| `TMessageBus` | Implementação principal de `IMensageria` |
| `TMensagem` | Implementação de `IMensagem` |
| `TMensagemDLQ` | Mensagem na DLQ (herda de `TMensagem`) |
| `TGerenciadorDLQMemoria` | DLQ em memória |
| `TSerializadorBinario` | Serialização binária |
| `TSerializadorJson` | Serialização JSON |

### Providers

| Provider | Classe | Protocolo |
|----------|--------|-----------|
| InMemory | `TProvedorMemoria` | Memória |
| Redis | `TProvedorRedis` | RESP (TCP) |
| RabbitMQ | `TProvedorRabbitMQ` | AMQP 0.9.1 (TCP) |

### Outbox

| Classe | Descrição |
|--------|-----------|
| `TMensagemOutbox` | Entidade ORM |
| `TRepositorioOutbox` | Repositório (salvar, listar pendentes, marcar status) |
| `TOutboxWorker` | Thread background que publica mensagens pendentes |
| `TOutboxMiddleware` | Facade (Iniciar/Parar) |
