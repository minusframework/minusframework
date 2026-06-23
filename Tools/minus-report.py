#!/usr/bin/env python3
"""
MinusMigrator Report — Gera relatórios de changelog em PDF/Markdown/HTML.

Uso:
  python minus-report.py changelog.json --format pdf
  python minus-report.py changelog.json --format markdown
  python minus-report.py changelog.json --format html

Dependências (apenas PDF):
  pip install fpdf2
"""

import sys
import json
import os
from datetime import datetime


def load_changelog(filepath: str) -> list:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if filepath.endswith('.yaml') or filepath.endswith('.yml'):
        import yaml
        return yaml.safe_load(content)
    return json.loads(content)


def generate_markdown(changes: list) -> str:
    lines = [
        "# 📋 Relatório de Migrations",
        f"Gerado em: {datetime.now().strftime('%d/%m/%Y %H:%M')}",
        f"Total de changesets: {len(changes)}",
        "",
        "| # | Tipo | Tabela | Coluna |",
        "|---|------|--------|--------|"
    ]

    for i, change in enumerate(changes, 1):
        tipo = change.get('tipo', change.get('changeType', 'N/A'))
        tabela = change.get('tabela', change.get('tableName', 'N/A'))
        coluna = change.get('colunaNome', change.get('columnName', '-'))
        lines.append(f"| {i} | {tipo} | {tabela} | {coluna} |")

    lines.extend([
        "",
        "---",
        f"*Relatório gerado por MinusMigrator Report*"
    ])
    return '\n'.join(lines)


def generate_html(changes: list) -> str:
    rows = []
    for i, change in enumerate(changes, 1):
        tipo = change.get('tipo', change.get('changeType', 'N/A'))
        tabela = change.get('tabela', change.get('tableName', 'N/A'))
        coluna = change.get('colunaNome', change.get('columnName', '-'))
        rows.append(f"<tr><td>{i}</td><td>{tipo}</td><td>{tabela}</td><td>{coluna}</td></tr>")

    return f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>MinusMigrator Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; max-width: 900px; margin: 40px auto; }}
        h1 {{ color: #2563eb; }}
        table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        th, td {{ border: 1px solid #ddd; padding: 8px 12px; text-align: left; }}
        th {{ background: #f0f4ff; }}
        .footer {{ color: #888; font-size: 12px; margin-top: 40px; }}
    </style>
</head>
<body>
    <h1>📋 Relatório de Migrations</h1>
    <p>Gerado em: {datetime.now().strftime('%d/%m/%Y %H:%M')} — Total: {len(changes)} changesets</p>
    <table>
        <tr><th>#</th><th>Tipo</th><th>Tabela</th><th>Coluna</th></tr>
        {''.join(rows)}
    </table>
    <p class="footer">Relatório gerado por MinusMigrator Report</p>
</body>
</html>"""


def generate_pdf(changes: list, output_file: str):
    try:
        from fpdf import FPDF
    except ImportError:
        print("ERRO: fpdf2 não instalado. Execute: pip install fpdf2")
        print("Fallback: gerando HTML...")
        html = generate_html(changes)
        html_file = output_file.replace('.pdf', '.html')
        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html)
        print(f"✅ Relatório HTML: {html_file}")
        return

    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", size=10)

    # Fontes Unicode
    pdf.add_font("NotoSans", "", r"c:\windows\fonts\arial.ttf", uni=True)
    pdf.set_font("NotoSans", "", 10)

    pdf.cell(200, 10, text="Relatorio de Migrations - MinusMigrator", align="C")
    pdf.ln(5)
    pdf.set_font("NotoSans", "", 8)
    for i, change in enumerate(changes, 1):
        tipo = str(change.get('tipo', change.get('changeType', 'N/A')))
        tabela = str(change.get('tabela', change.get('tableName', 'N/A')))
        coluna = str(change.get('colunaNome', change.get('columnName', '-')))
        pdf.cell(10, 6, str(i), border=1)
        pdf.cell(60, 6, tipo[:30], border=1)
        pdf.cell(70, 6, tabela[:35], border=1)
        pdf.cell(50, 6, coluna[:25], border=1)
        pdf.ln()

    pdf.output(output_file)
    print(f"✅ Relatório PDF: {output_file}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    filepath = sys.argv[1]
    if not os.path.exists(filepath):
        print(f"ERRO: Arquivo não encontrado: {filepath}")
        sys.exit(1)

    fmt = next((a.replace('--format=', '').replace('--format ', '') 
                for a in sys.argv if a.startswith('--format')), 'markdown')
    
    changes = load_changelog(filepath)

    if fmt == 'pdf':
        output = filepath.replace('.json', '.pdf').replace('.yaml', '.pdf').replace('.yml', '.pdf')
        generate_pdf(changes, output)
    elif fmt == 'html':
        html = generate_html(changes)
        output = filepath.replace('.json', '.html').replace('.yaml', '.html').replace('.yml', '.html')
        with open(output, 'w', encoding='utf-8') as f:
            f.write(html)
        print(f"✅ Relatório HTML: {output}")
    else:  # markdown
        md = generate_markdown(changes)
        output = filepath.replace('.json', '.md').replace('.yaml', '.md').replace('.yml', '.md')
        with open(output, 'w', encoding='utf-8') as f:
            f.write(md)
        print(f"✅ Relatório Markdown: {output}")


if __name__ == '__main__':
    main()
