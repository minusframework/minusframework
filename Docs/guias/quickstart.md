# Guia de Início Rápido

## 1. Configurar Conexão

```pascal
program MeuApp;

uses
  MF.Config,
  MF.Provider.FireDAC.SQLite;

begin
  // SQLite local
  TConfiguracaoORM.Configurar('SQLite:///C:\Dados\meu_app.db');

  // Ou Firebird
  // TConfiguracaoORM.Configurar(
  //   'FB://localhost:3050/C:\Dados\MEUAPP.FDB?user=SYSDBA&password=masterkey');
end.
```

## 2. Definir Entidade

```pascal
type
  [Tabela('CLIENTES')]
  TCliente = class
  private
    FId: Integer;
    FNome: string;
    FEmail: string;
  public
    [ChavePrimaria(eiIdentidade)]
    [Coluna('ID_CLIENTE')]
    property Id: Integer read FId write FId;

    [Coluna('NOME')]
    property Nome: string read FNome write FNome;

    [Coluna('EMAIL')]
    property Email: string read FEmail write FEmail;
  end;
```

## 3. CRUD

```pascal
var
  LRepo: IRepositorioBase<TCliente>;
  LCliente: TCliente;
  LClientes: TObjectList<TCliente>;
begin
  LRepo := TRepositorioBase<TCliente>.Create(
    TConfiguracaoORM.ConexaoPadrao);

  // Inserir
  LCliente := TCliente.Create;
  LCliente.Nome := 'João';
  LCliente.Email := 'joao@email.com';
  LRepo.Salvar(LCliente);
  WriteLn('ID gerado: ', LCliente.Id);

  // Buscar
  LCliente := LRepo.BuscarPorId(LCliente.Id);

  // Listar
  LClientes := LRepo.BuscarTodos;

  // Atualizar
  LCliente.Nome := 'João Silva';
  LRepo.Salvar(LCliente);

  // Excluir
  LRepo.Excluir(LCliente.Id);
end;
```

## 4. Migração (opcional)

```powershell
# Inicializar
MinusMigrator_CLI.exe init --connection "SQLite:///C:\Dados\meu_app.db"

# Criar migração
MinusMigrator_CLI.exe add-migration "CriarTabelaClientes"

# Executar
MinusMigrator_CLI.exe migrate --connection "SQLite:///C:\Dados\meu_app.db"
```

## 5. Docker (bancos para testes)

```powershell
docker compose up -d
```

### Próximos passos

- [Configuração detalhada](configuration.md)
- [Exemplo de CRUD completo](../exemplos/basic-crud.md)
- [Referência do ORM](../02-ORM/README.md)
