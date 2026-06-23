# Análise Arquitetural: Monorepo vs. Multirrepositórios com Submódulos

Esta análise avalia a proposta de dividir o **MinusFramework** em múltiplos repositórios separados (por exemplo, `minus-orm`, `minus-messaging`, `minus-migrator`, `minus-telemetry`) vinculados a um repositório central via **Git Submodules**, comparando com abordagens alternativas comuns em Delphi.

---

## 1. Visão Geral das Estratégias

| Critério | Monorepo (Atual) | Multirrepos com Submódulos | Monorepo + Package Manager (Boss) |
| :--- | :--- | :--- | :--- |
| **Complexidade Git** | Baixíssima | Alta (Submódulos exigem atenção extra) | Baixa |
| **Refatoração Cruzada** | Muito Fácil | Difícil (Exige múltiplos commits/pushes) | Muito Fácil |
| **Modularidade Física** | Média | Altíssima (Isolamento físico total) | Alta (Modularidade via dependência) |
| **Ciclo de Integração CI** | Único (Simples) | Fragmentado (Múltiplas pipelines) | Único ou Fragmentado |
| **Curva de Aprendizado** | Nula | Média/Alta | Baixa |

---

## 2. Prós de Separar em Repositórios + Submódulos

### A) Isolamento Rígido de Dependências (Controle de Acoplamento)
Ao separar fisicamente o `minus-messaging` do `minus-orm`, é **fisicamente impossível** ocorrer acoplamento indesejado entre eles (como o uses indesejado que vimos na análise anterior), a menos que uma dependência explícita seja declarada no gerenciador de pacotes ou caminhos de busca do projeto.

### B) Versionamento e Ciclo de Vida Independentes (Sem SemVer Global)
Se o `minus-orm` precisar de uma correção urgente e subir para a versão `v1.2.1`, o `minus-messaging` pode continuar na versão `v2.0.0` estável, sem a necessidade de re-homologar e gerar tags globais para todo o framework.

### C) Distribuição Comercial Flexível (Dual Licensing)
Como o framework possui planos de licenciamento separados (Comunity vs Pro, ORM Bundle, etc.), separar os códigos facilita a entrega. Um cliente que assina apenas o *ORM Pro* recebe acesso apenas ao repositório do `minus-orm-pro`, sem expor o código do `minus-messaging-pro` ou painéis do `minus-telemetry`.

---

## 3. Contras e Riscos de usar Git Submodules (Especialmente no Delphi)

### A) Fricção no Desenvolvimento Diário
O Git Submodule não rastreia arquivos diretamente, mas sim um **commit SHA específico** do repositório filho.
* Se você alterar o `minus-orm` e o `minus-messaging` ao mesmo tempo durante uma refatoração, terá que fazer o Commit/Push dentro de cada submódulo e, em seguida, fazer um terceiro commit no repositório pai atualizando as referências.
* Esquecer de dar Push em um submódulo quebrará o build de todos os outros desenvolvedores da equipe com o erro `fatal: reference is not a tree`.

### B) Quebra de Caminhos Relativos no RAD Studio
Os arquivos do Delphi (`.dproj` e `.groupproj`) salvam caminhos de busca físicos e relativos (ex: `..\Source\Core`). 
Se um desenvolvedor clonar o repositório central sem o parâmetro `--recursive`, as pastas dos submódulos virão vazias, quebrando imediatamente a compilação no RAD Studio e gerando reclamações de *"arquivo não encontrado"*.

### C) Fricção em Refatorações Globais
Se você alterar uma interface na unit base [MF.Connection.pas](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Bibliotecas/MF.Connection.pas), terá que propagar essa alteração por 5 repositórios diferentes de forma sequencial. O trabalho de desenvolvimento se torna muito mais lento.

---

## 4. A Alternativa Recomendada: Monorepo + Gerenciador de Pacotes (Boss)

No ecossistema Delphi moderno (especialmente usando Horse), a ferramenta padrão de mercado para gerenciamento de dependências é o **Boss** (gerenciador de dependências por linha de comando parecido com o npm/cargo).

Em vez de usar Git Submodules, você pode **manter um Monorepo único** para o desenvolvimento interno, mas expor múltiplos pacotes através do **Boss**.

```
MinusFramework/ (Repositório Único)
├── Source/
│   ├── Core/
│   │   ├── boss.json            <-- Define o pacote "minus-orm"
│   │   └── ...
│   ├── Messaging/
│   │   ├── boss.json            <-- Define "minus-messaging" (depende de Core)
│   │   └── ...
│   └── Telemetry/
│       ├── boss.json            <-- Define "minus-telemetry" (depende de Core)
│       └── ...
```

### Como o cliente instala:
Se o cliente quer apenas o ORM, ele roda no terminal do projeto dele:
```bash
boss install github.com/seu-usuario/MinusFramework/Source/Core
```
Se ele quer mensageria:
```bash
boss install github.com/seu-usuario/MinusFramework/Source/Messaging
```
O Boss baixa apenas a pasta solicitada e resolve as dependências automaticamente de forma limpa, sem a complexidade dos submódulos do Git para a sua equipe de engenharia.

---

## 💡 Parecer do Arquiteto

> [!IMPORTANT]
> **Recomendação:** **Evite Git Submodules** se a equipe for pequena ou média. A complexidade operacional do Git e a manutenção dos caminhos relativos do Delphi (`.dproj`) costumam anular os benefícios do isolamento.
>
> Adote a estratégia de **Monorepo Modularizado com Boss**. Isso mantém a agilidade de refatoração do time interno (tudo em um único lugar) e oferece uma experiência de instalação limpa e desacoplada para os usuários do framework.
