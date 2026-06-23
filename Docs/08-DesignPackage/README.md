# Design-time Packages

**Pacotes:**
- `MinusFramework_Design.dpk`
- `MinusMessaging_Design.dpk`

**Diretório:** `Source\Bibliotecas\MF.ORM.Expert.pas`, `Source\Messaging\MF.Messaging.Expert.pas`

Pacotes de design-time para integrar o MinusFrameWork com a IDE do Delphi.

---

## MinusFramework_Design

### IDE Expert (`MF.ORM.Expert.pas`)

Wizard que auxilia na configuração inicial do ORM:

- Cria conexão padrão
- Registra providers na IDE
- Gera código boilerplate

### Componentes Registrados

Após instalar o pacote, os seguintes componentes aparecem na paleta:

| Componente | Aba | Descrição |
|------------|-----|-----------|
| `TMinusDataSet` | MinusORM | `TDataSet` bridge para grids VCL |
| `TMinusConexao` | MinusORM | Componente de conexão |

### Instalação

1. **Component → Install Packages**
2. **Add →** selecionar `MinusFramework_Design.bpl`
3. Clicar **OK**

Os componentes aparecem na paleta na aba **MinusORM**.

### Desinstalação

1. **Component → Install Packages**
2. Selecionar `MinusFramework_Design`
3. Clicar **Remove**

---

## MinusMessaging_Design

### IDE Expert (`MF.Messaging.Expert.pas`)

Wizard para configuração de mensageria:

- Cria instância de `TMessageBus`
- Configura provedor
- Gera código de publish/consume

### Instalação

Mesmo processo do `MinusFramework_Design`.

---

## Ordem de construção

Os pacotes design dependem dos runtime packages correspondentes:

1. Buildar `MinusFramework_Runtime` primeiro
2. Buildar `MinusFramework_Design` depois
3. Buildar `MinusMessaging_Runtime` primeiro
4. Buildar `MinusMessaging_Design` depois
