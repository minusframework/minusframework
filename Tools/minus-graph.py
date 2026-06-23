#!/usr/bin/env python3
"""
MinusMigrator Graph — Gera diagrama ER (Entidade-Relacionamento) do schema.

Uso:
  python minus-graph.py schema.json --format png
  python minus-graph.py schema.json --format svg
  python minus-graph.py schema.json --format dot

Dependências:
  pip install graphviz  (para PNG/SVG)
  ou instalar Graphviz: https://graphviz.org/download/
"""

import sys
import json
import os


def load_schema(filepath: str) -> dict:
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def generate_dot(schema: dict) -> str:
    """Gera arquivo DOT (Graphviz) a partir do schema."""
    lines = [
        'digraph MinusFramework {',
        '    rankdir=LR;',
        '    node [shape=record, fontname="Arial", fontsize=10];',
        '    edge [fontname="Arial", fontsize=8];',
        ''
    ]

    tables = schema.get('tables', schema.get('tabelas', []))
    relationships = schema.get('relationships', schema.get('relacionamentos', schema.get('foreignKeys', [])))

    for table in tables:
        name = table.get('name', table.get('nome', 'unknown'))
        columns = table.get('columns', table.get('colunas', []))
        
        col_strs = []
        for col in columns:
            cname = col.get('name', col.get('nome', '?'))
            ctype = col.get('type', col.get('tipo', '?'))
            pk = '🔑 ' if col.get('primaryKey', col.get('chavePrimaria', False)) else ''
            col_strs.append(f'{pk}{cname} ({ctype})')
        
        label = f"{name} | " + "\\l".join(col_strs) + "\\l"
        lines.append(f'    "{name}" [label="{{ {label} }}"];')
    
    lines.append('')

    for rel in relationships:
        fk_table = rel.get('table', rel.get('tabela', ''))
        fk_cols = rel.get('columns', rel.get('colunas', []))
        ref_table = rel.get('referencedTable', rel.get('tabelaReferenciada', ''))
        rel_name = rel.get('name', rel.get('nome', f'{fk_table}_fk'))

        if isinstance(fk_cols, list):
            fk_cols = ', '.join(fk_cols)
        
        lines.append(f'    "{fk_table}" -> "{ref_table}" [label="{rel_name}\\n({fk_cols})", fontsize=7];')

    lines.append('}')
    return '\n'.join(lines)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    filepath = sys.argv[1]
    if not os.path.exists(filepath):
        print(f"ERRO: Arquivo não encontrado: {filepath}")
        sys.exit(1)

    fmt = next((a.replace('--format=', '').replace('--format ', '') 
                for a in sys.argv if a.startswith('--format')), 'png')

    schema = load_schema(filepath)
    dot = generate_dot(schema)

    dot_file = filepath.replace('.json', '.dot')
    with open(dot_file, 'w', encoding='utf-8') as f:
        f.write(dot)
    print(f"✅ DOT gerado: {dot_file}")

    if fmt in ('png', 'svg', 'pdf'):
        try:
            import graphviz
            gv = graphviz.Source(dot)
            output = filepath.replace('.json', f'.{fmt}')
            gv.render(filename=output.replace(f'.{fmt}', ''), format=fmt, cleanup=True)
            print(f"✅ Diagrama {fmt.upper()}: {output}")
        except ImportError:
            print("⚠️  Graphviz Python não instalado. Execute: pip install graphviz")
            print(f"   Ou use o arquivo DOT gerado: {dot_file}")
            print(f"   Comando manual: dot -T{fmt} {dot_file} -o schema.{fmt}")


if __name__ == '__main__':
    main()
