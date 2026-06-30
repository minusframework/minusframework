# Exemplo: CRUD Completo

## DefiniÃ§Ã£o da Entidade

```pascal
unit MeuModel.Produto;

interface

uses
  System.Generics.Collections,
  MF.Attributes;

type
  [Tabela('PRODUTOS')]
  TProduto = class
  private
    FId: Integer;
    FNome: string;
    FPreco: Currency;
    FAtivo: Boolean;
    FCriadoEm: TDateTime;
  public
    [ChavePrimaria(eiIdentidade)]
    [Coluna('ID')]
    property Id: Integer read FId write FId;

    [Coluna('NOME')]
    [Obrigatorio]
    [TamanhoMaximo(100)]
    property Nome: string read FNome write FNome;

    [Coluna('PRECO')]
    property Preco: Currency read FPreco write FPreco;

    [Coluna('ATIVO')]
    property Ativo: Boolean read FAtivo write FAtivo;

    [CriadoEm]
    [Coluna('CRIADO_EM')]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

implementation

end.
```

## AplicaÃ§Ã£o Principal

```pascal
program MinhaApp;

uses
  System.SysUtils,
  System.Generics.Collections,
  MF.Config,
  MF.Provider.FireDAC.SQLite,
  MF.RepositoryBase,
  MeuModel.Produto;

var
  LRepo: IRepositorioBase<TProduto>;
  LProduto: TProduto;
  LProdutos: TObjectList<TProduto>;

begin
  // Configurar
  TConfiguracaoORM.Configurar('SQLite:///C:/Dados/estoque.db');

  LRepo := TRepositorioBase<TProduto>.Create(
    TConfiguracaoORM.ConexaoPadrao);

  // --- Inserir ---
  LProduto := TProduto.Create;
  LProduto.Nome := 'Teclado MecÃ¢nico';
  LProduto.Preco := 299.90;
  LProduto.Ativo := True;
  LRepo.Salvar(LProduto);
  WriteLn('Produto inserido. ID: ', LProduto.Id);

  // --- Buscar por ID ---
  LProduto := LRepo.BuscarPorId(LProduto.Id);
  try
    WriteLn('Nome: ', LProduto.Nome);
    WriteLn('PreÃ§o: ', LProduto.Preco.ToString);
  finally
    LProduto.Free;
  end;

  // --- Buscar todos ---
  LProdutos := LRepo.BuscarTodos;
  try
    WriteLn('Total de produtos: ', LProdutos.Count);
    for var LItem in LProdutos do
      WriteLn(Format('  %d - %s - R$ %.2f',
        [LItem.Id, LItem.Nome, LItem.Preco]));
  finally
    LProdutos.Free;
  end;

  // --- Atualizar ---
  LProduto := LRepo.BuscarPorId(1);
  try
    LProduto.Preco := 349.90;
    LRepo.Salvar(LProduto);
    WriteLn('Produto atualizado.');
  finally
    LProduto.Free;
  end;

  // --- Excluir ---
  LRepo.Excluir(2);
  WriteLn('Produto excluÃ­do.');

  ReadLn;
end.
```

## Com Criteria API

```pascal
uses
  MF.Criteria,
  MF.SelectBuilder;

// Produtos ativos com preÃ§o > 100
LProdutos := TRepositorioORM<TProduto>
  .Consulta(TConfiguracaoORM.ConexaoPadrao)
  .Onde(Criterio('ATIVO').Igual(True))
  .Onde(Criterio('PRECO').MaiorQue(100))
  .OrdenarPor('NOME', oaAsc)
  .ParaLista;

// Com paginaÃ§Ã£o
LResultado := TRepositorioORM<TProduto>
  .Consulta(TConfiguracaoORM.ConexaoPadrao)
  .Onde(Criterio('ATIVO').Igual(True))
  .Paginar(1, 10);
```
