#!/usr/bin/env python3
"""
MinusMigrator YAML Bridge — Conversor YAML ↔ JSON.

Uso:
  python minus-yaml.py to-json < arquivo.yaml
  python minus-yaml.py to-yaml < arquivo.json
  python minus-yaml.py to-json arquivo.yaml
  python minus-yaml.py to-yaml arquivo.json

Integração com Delphi:
  TProcess.Execute('python Tools/minus-yaml.py to-json changelog.yaml > changelog.json')
"""

import sys
import json
import os

try:
    import yaml
except ImportError:
    print("ERRO: PyYAML não instalado. Execute: pip install pyyaml")
    sys.exit(1)


def yaml_to_json(input_str: str) -> str:
    data = yaml.safe_load(input_str)
    return json.dumps(data, indent=2, ensure_ascii=False)


def json_to_yaml(input_str: str) -> str:
    data = json.loads(input_str)
    return yaml.dump(data, allow_unicode=True, sort_keys=False, default_flow_style=False)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1]

    if len(sys.argv) >= 3:
        filepath = sys.argv[2]
        if not os.path.exists(filepath):
            print(f"ERRO: Arquivo não encontrado: {filepath}")
            sys.exit(1)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    else:
        content = sys.stdin.read()

    if command == 'to-json':
        print(yaml_to_json(content))
    elif command == 'to-yaml':
        print(json_to_yaml(content))
    elif command == 'validate':
        try:
            yaml.safe_load(content)
            print("✅ YAML válido")
        except yaml.YAMLError as e:
            print(f"❌ YAML inválido: {e}")
            sys.exit(1)
    else:
        print(f"Comando desconhecido: {command}")
        print(__doc__)
        sys.exit(1)


if __name__ == '__main__':
    main()
