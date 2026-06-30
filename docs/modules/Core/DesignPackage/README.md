# Design-time Packages

**Pacotes:**
- `MinusFramework_Design.dpk`
- `MinusMessaging_Design.dpk`

**DiretÃ³rio:** `Source\Bibliotecas\MF.ORM.Expert.pas`, `Source\Messaging\MF.Messaging.Expert.pas`

Pacotes de design-time para integrar o MinusFrameWork com a IDE do Delphi.

---

## MinusFramework_Design

### IDE Expert (`MF.ORM.Expert.pas`)

Wizard que auxilia na configuraÃ§Ã£o inicial do ORM:

- Cria conexÃ£o padrÃ£o
- Registra providers na IDE
- Gera cÃ³digo boilerplate

### Componentes Registrados

ApÃ³s instalar o pacote, os seguintes componentes aparecem na paleta:

| Componente | Aba | DescriÃ§Ã£o |
|------------|-----|-----------|
| `TMinusDataSet` | MinusORM | `TDataSet` bridge para grids VCL |
| `TMinusConexao` | MinusORM | Componente de conexÃ£o |

### InstalaÃ§Ã£o

1. **Component â†’ Install Packages**
2. **Add â†’** selecionar `MinusFramework_Design.bpl`
3. Clicar **OK**

Os componentes aparecem na paleta na aba **MinusORM**.

### DesinstalaÃ§Ã£o

1. **Component â†’ Install Packages**
2. Selecionar `MinusFramework_Design`
3. Clicar **Remove**

---

## MinusMessaging_Design

### IDE Expert (`MF.Messaging.Expert.pas`)

Wizard para configuraÃ§Ã£o de mensageria:

- Cria instÃ¢ncia de `TMessageBus`
- Configura provedor
- Gera cÃ³digo de publish/consume

### InstalaÃ§Ã£o

Mesmo processo do `MinusFramework_Design`.

---

## Ordem de construÃ§Ã£o

Os pacotes design dependem dos runtime packages correspondentes:

1. Buildar `MinusFramework_Runtime` primeiro
2. Buildar `MinusFramework_Design` depois
3. Buildar `MinusMessaging_Runtime` primeiro
4. Buildar `MinusMessaging_Design` depois
