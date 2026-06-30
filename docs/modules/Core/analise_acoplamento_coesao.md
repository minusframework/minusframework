# AnÃ¡lise de Acoplamento e CoesÃ£o â€” MinusFramework

Este documento apresenta uma anÃ¡lise tÃ©cnica profunda sobre o **acoplamento** (coupling) e a **coesÃ£o** (cohesion) do cÃ³digo-fonte do **MinusFramework**, identificando pontos fortes do design atual e vazamentos estruturais (design leaks) que necessitam de refatoraÃ§Ã£o para garantir a extensibilidade do ORM.

---

## 1. AnÃ¡lise de CoesÃ£o (Cohesion)

De forma geral, o MinusFramework apresenta **alta coesÃ£o**. A maioria das classes e mÃ³dulos possui responsabilidades muito bem delimitadas e focadas em uma Ãºnica Ã¡rea de atuaÃ§Ã£o.

### âœ… Pontos Fortes (Alta CoesÃ£o)
* **[TCacheMetadados](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Core/MF.MetadataCache.pas#L58):** Extremamente coeso. Sua Ãºnica finalidade Ã© ler via RTTI as anotaÃ§Ãµes das classes de entidade, compilar as strings de comando SQL estÃ¡ticas correspondentes (Select, Insert, Update, Delete) e armazenÃ¡-las de forma thread-safe na inicializaÃ§Ã£o.
* **[TConstrutorSelecao](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Core/MF.SelectBuilder.pas#L23):** CoesÃ£o funcional excelente. Tem a Ãºnica responsabilidade de construir e executar de forma fluente instruÃ§Ãµes SQL SELECT, abstraindo a Criteria API e a paginaÃ§Ã£o.
* **[TRastreadorMudancas](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Core/MF.ChangeTracker.pas#L21):** Focado puramente em gerar snapshots de valores antigos de propriedades e calcular deltas de alteraÃ§Ã£o (dirty tracking) para as entidades.

### âš ï¸ Oportunidades de Melhoria (CoesÃ£o Local)
* **Procedimentos Soltos no `implementation` de [MF.UnitOfWork.pas](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Core/MF.UnitOfWork.pas):**
  FunÃ§Ãµes como `DefinirIdEntidade`, `VincularIdChave`, `ExecutarInsercaoComRetorno`, `ExecutarInsercaoSemRetorno` e `ExecutarExclusao` estÃ£o declaradas como rotinas livres na seÃ§Ã£o de implementaÃ§Ã£o da unit.
  * *Problema:* Embora isso mantenha a interface da classe `TUnidadeTrabalho` limpa, move regras pesadas de geraÃ§Ã£o e persistÃªncia SQL fÃ­sica diretamente para o arquivo que deveria ser responsÃ¡vel *apenas* por gerenciar transaÃ§Ãµes e registrar estados das entidades.
  * *SoluÃ§Ã£o:* Mover essas rotinas utilitÃ¡rias de execuÃ§Ã£o SQL fÃ­sica para um executor dedicado (ex: `TComandoPersistencia` ou em helpers de mapeamento).

---

## 2. AnÃ¡lise de Acoplamento (Coupling)

O acoplamento Ã© o ponto mais crÃ­tico da arquitetura atual. Embora o framework implemente o padrÃ£o de pipeline/hooks para desacoplar as extensÃµes do nÃºcleo, existem **vazamentos estruturais de acoplamento forte** que impedem o funcionamento modular do ORM.

### âœ… Pontos Fortes (Desacoplamento por Pipeline)
* A unit [MF.Extensao.Core.pas](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Core/MF.Extensao.Core.pas) define uma infraestrutura fantÃ¡stica de hooks baseada em interfaces (`IProcessadorInsercao`, `IProcessadorAtualizacao`, `IProcessadorExclusao`).
* O singleton `TRegistroProcessadores` funciona como uma central de despacho, permitindo que as units de auditoria ([MF.Extensions.Audit.pas](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Extensions/MF.Extensions.Audit.pas#L282-L286)) e cache se registrem de forma transparente durante a inicializaÃ§Ã£o (bloco `initialization`), sem que o nÃºcleo conheÃ§a a implementaÃ§Ã£o fÃ­sica delas.

### âŒ Pontos CrÃ­ticos (Acoplamento Forte e Vazamento de DependÃªncias)

```mermaid
classDiagram
    class TRepositorioBase {
        <<Core>>
    }
    class TAjudanteAuditoria {
        <<Extension>>
    }
    class TAjudanteCache {
        <<Extension>>
    }
    class TClonador {
        <<Extension>>
    }

    TRepositorioBase --> TAjudanteAuditoria : Acoplamento Forte (Uses Direto)
    TRepositorioBase --> TAjudanteCache : Acoplamento Forte (Uses Direto)
    TRepositorioBase --> TClonador : Acoplamento Forte (Uses Direto)
    
    note for TRepositorioBase "Se o usuÃ¡rio remover as units de Audit ou Cache do projeto,\n o nÃºcleo do ORM deixa de compilar!"
```

#### A) Acoplamento FÃ­sico de ExtensÃµes na clÃ¡usula `uses` do NÃºcleo
Na seÃ§Ã£o `implementation` da unit core [MF.RepositoryBase.pas](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Core/MF.RepositoryBase.pas#L116-L121), encontramos dependÃªncias diretas de implementaÃ§Ãµes do diretÃ³rio `/Extensions`:
```pascal
uses
  MF.Extensions.Cache,
  MF.Extensions.Audit,
  MF.Extensions.Relacionamento,
  MF.Extensions.Bulk,
  ...
```
* **ConsequÃªncia:** Isso viola a modularidade. Se o desenvolvedor desejar compilar uma versÃ£o lightweight do ORM sem suporte a cache de segundo nÃ­vel ou auditoria, ele **nÃ£o consegue**, pois o compilador do Delphi exige a presenÃ§a dessas units fÃ­sicas do diretÃ³rio de extensÃµes para compilar a unit do repositÃ³rio bÃ¡sico.

#### B) O "Vazamento" de Assinatura no Pipeline de ExclusÃ£o (TObject vs ID)
No mÃ©todo [TRepositorioBase\<T>.Excluir](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Core/MF.RepositoryBase.pas#L335), o repositÃ³rio recebe apenas o ID da entidade (`AIdentificador: Integer`), sem possuir a instÃ¢ncia fÃ­sica do objeto (`TObject`).
A interface do pipeline de exclusÃ£o exige a instÃ¢ncia do objeto:
```pascal
IProcessadorExclusao = interface
  procedure AposExcluir(const AConexao: IConexao; const AEntidade: TObject);
end;
```
* **O Desvio:** Como o pipeline nÃ£o possui uma assinatura capaz de lidar apenas com o ID, os desenvolvedores burlaram o fluxo do pipeline e acoplaram diretamente o repositÃ³rio ao helper estÃ¡tico da extensÃ£o de auditoria:
```pascal
// Trecho acoplado dentro do RepositÃ³rio Core:
TAjudanteAuditoria.RegistrarExclusaoPorId(FConexao, TClass(T), AIdentificador);
```

#### C) Acoplamento Direto em Consultas de Cache
No mÃ©todo `BuscarPorId`, o repositÃ³rio realiza chamadas estÃ¡ticas diretas para verificar e ler dados do cache:
```pascal
LUsarCache := TAjudanteCache.CacheHabilitado(TClass(T));
// ...
Exit(TClonador.Clonar<T>(T(LObj)));
```
Tanto `TAjudanteCache` quanto `TClonador` pertencem Ã  unit de extensÃ£o [MF.Extensions.Cache.pas](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Extensions/MF.Extensions.Cache.pas).

---

## 3. Plano de AÃ§Ã£o para CorreÃ§Ã£o (RefatoraÃ§Ã£o de Arquitetura)

Para obter um ORM verdadeiramente modular com acoplamento fraco (Loose Coupling), a arquitetura deve ser refatorada seguindo a **InversÃ£o de DependÃªncia (DIP)**:

### 1. Ajustar as assinaturas do Pipeline
Adicionar suporte a operaÃ§Ãµes baseadas em chaves/identificadores nas interfaces do pipeline em [MF.Extensao.Core.pas](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Core/MF.Extensao.Core.pas):
```pascal
IProcessadorExclusao = interface
  ['{4B5C6D7E-8F9A-4B0C-1D2E-3F4A5B6C7D8E}']
  function UsarExclusaoLogica(const AClasse: TClass): Boolean;
  function GerarSQLExclusao(const AClasse: TClass; const AColunaChave: string): string;
  procedure AposExcluir(const AConexao: IConexao; const AEntidade: TObject);
  
  // NOVA ASSINATURA DESACOPLADA:
  procedure AposExcluirPorId(const AConexao: IConexao; const AClasse: TClass; const AId: Integer);
end;
```
Com isso, o repositÃ³rio bÃ¡sico chamarÃ¡ apenas `TRegistroProcessadores.AposExcluirPorId` e a extensÃ£o de Auditoria interceptarÃ¡ a chamada, removendo a referÃªncia a `TAjudanteAuditoria` do nÃºcleo do repositÃ³rio.

### 2. Introduzir Interface de Cache GenÃ©rica
Mover a interface `ICacheProvedor` e as definiÃ§Ãµes do clonador para o pacote bÃ¡sico [MF.Types.pas](file:///C:/Users/Gabriel/OneDrive/Documentos/MinusFrameWork/Source/Bibliotecas/MF.Types.pas) ou criar uma unit de contratos comum `MF.Contracts.Cache.pas`. O repositÃ³rio passarÃ¡ a consumir apenas a abstraÃ§Ã£o da interface de cache, cuja instÃ¢ncia real serÃ¡ fornecida pelo `TConfiguracaoORM.Cache` (que funciona como um Service Locator).
