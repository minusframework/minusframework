# MinusFrameWork License Server

Este diretório contém o código do License Server, movido para repositório privado.

**Repositório:** `https://github.com/GabrielFerreiraMendes/minusframework-license-server` (privado)

O servidor gera chaves de licença RSA-2048 para os tiers Free/Pro/Enterprise.
Está rodando como serviço Windows em `http://localhost:3456`.

Para gerenciar o serviço local:
- `nssm\nssm.exe restart MinusLicenseServer`
- Logs em `logs\stdout.log` e `logs\stderr.log`
