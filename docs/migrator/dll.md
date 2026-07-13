---
title: "DLL — C-API"
---

<span class="badge badge-free">Free</span>

# DLL — C-API

O MinusMigrator também é distribuído como uma DLL com interface C para integração com outras linguagens.

## Funções Exportadas

```c
// Aplica migrações pendentes
int Migrator_Up(const char* conexao, const char* diretorio);

// Reverte migrações
int Migrator_Down(const char* conexao, int steps);

// Lista status das migrações
char* Migrator_Status(const char* conexao);

// Cria novo arquivo de migração
int Migrator_Create(const char* nome);

// Libera string alocada pela DLL
void Migrator_FreeString(char* str);

// Verifica versão mais recente no GitHub
int Migrator_CheckVersion(const char* versaoAtual, char** resultado);
```

## Exemplo em C#

```csharp
[DllImport("MinusMigrator.dll")]
static extern int Migrator_Up(string conexao, string diretorio);

void AplicarMigracoes()
{
    int result = Migrator_Up("MinhaConexao", "./Migrations");
    if (result == 0)
        Console.WriteLine("Migracoes aplicadas com sucesso");
    else
        Console.WriteLine("Erro ao aplicar migracoes");
}
```

## Exemplo em Python

```python
import ctypes

dll = ctypes.CDLL("MinusMigrator.dll")
dll.Migrator_Up.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
dll.Migrator_Up.restype = ctypes.c_int

result = dll.Migrator_Up(b"MinhaConexao", b"./Migrations")
print("OK" if result == 0 else "Erro")
```

## Exemplo: Verificação de Versão em C#

```csharp
[DllImport("MinusMigrator.dll")]
static extern int Migrator_CheckVersion(string versaoAtual, out IntPtr resultado);

void VerificarVersao()
{
    IntPtr ptr;
    int code = Migrator_CheckVersion("1.0.0", out ptr);
    string versao = Marshal.PtrToStringAnsi(ptr);
    Migrator_FreeString(ptr);
    if (code == 4)
        Console.WriteLine($"Nova versao disponivel: {versao}");
    else
        Console.WriteLine($"Versao atualizada: {versao}");
}
```

## Exemplo: Verificação de Versão em Python

```python
dll.Migrator_CheckVersion.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_char_p)]
dll.Migrator_CheckVersion.restype = ctypes.c_int

versao_atual = b"1.0.0"
resultado = ctypes.c_char_p()
code = dll.Migrator_CheckVersion(versao_atual, ctypes.byref(resultado))
if code == 4:
    print(f"Nova versao disponivel: {resultado.value.decode()}")
else:
    print(f"Versao atualizada: {resultado.value.decode()}")
dll.Migrator_FreeString(resultado)
```

## Códigos de Retorno

| Código | Significado |
|--------|-------------|
| `0` | Sucesso |
| `1` | Conexão não encontrada |
| `2` | Diretório de migrações inválido |
| `3` | Erro ao executar SQL |
| `4` | Versão desatualizada — nova versão disponível no GitHub |
