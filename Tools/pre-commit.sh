#!/bin/bash
# ================================================
# MinusFramework Pre-Commit Hook
# Valida a constituição do projeto antes de commitar
# ================================================
# Instalar: cp Tools/pre-commit.sh .git/hooks/pre-commit
# ================================================

echo "🛡️  Constitution Guard — Pre-Commit Check"
echo "============================================"
violations=0

# 0. Verificar hints/warnings comuns (H2443, H2164, W1035)
echo "🚫 Zero Warnings/Hints..."
for f in $(git diff --cached --name-only --diff-filter=ACM | grep '\.pas$'); do
  if [ -f "$f" ]; then
    # H2443: TValue.GetTypeInfo sem System.TypInfo
    if grep -q "GetTypeInfo\|TValue\.GetTypeInfo" "$f" 2>/dev/null; then
      if ! grep -q "System\.TypInfo" "$f" 2>/dev/null; then
        echo "  ⚠️  $f: TValue.GetTypeInfo sem System.TypInfo (H2443)"
      fi
    fi
    # H2443: TDataSet methods sem Data.DB
    if grep -q "FieldCount\|RecordCount\|Fields\[" "$f" 2>/dev/null; then
      if ! grep -q "Data\.DB" "$f" 2>/dev/null; then
        echo "  ⚠️  $f: TDataSet methods sem Data.DB (H2443)"
      fi
    fi
  fi
done

# 1. Verificar magic numbers
echo "🔍 Magic numbers..."
for f in $(git diff --cached --name-only --diff-filter=ACM | grep '\.pas$'); do
  if [ -f "$f" ]; then
    magic=$(grep -nP '(?<![:\w])\s[3-9]\d{1,}(?!\s*//)' "$f" 2>/dev/null | grep -v "Copyright\|1000\|2048\|65535" | head -3)
    if [ -n "$magic" ]; then
      echo "  ⚠️  $f: possíveis magic numbers"
    fi
  fi
done

# 2. Verificar dependências proibidas (Core → Migrator)
echo "🔍 Dependências proibidas..."
for f in $(git diff --cached --name-only --diff-filter=ACM | grep 'Source/Core/.*\.pas$'); do
  if grep -q "MF\.Migrator" "$f" 2>/dev/null; then
    echo "  🔴 $f: importa MF.Migrator (Core não pode depender de Migrator)"
    violations=$((violations+1))
  fi
done

# 3. Verificar god units (>500 linhas)
echo "🔍 God units..."
for f in $(git diff --cached --name-only --diff-filter=ACM | grep '\.pas$'); do
  lines=$(wc -l < "$f" 2>/dev/null)
  if [ "$lines" -gt 500 ]; then
    echo "  ⚠️  $f: $lines linhas (limite: 500)"
  fi
done

# 4. Verificar interface uses (>9 deps MF)
echo "🔍 Acoplamento..."
for f in $(git diff --cached --name-only --diff-filter=ACM | grep '\.pas$'); do
  deps=$(sed -n '/^interface/,/^implementation/p' "$f" 2>/dev/null | grep -cP "^\s+MF\.")
  if [ "$deps" -gt 9 ]; then
    echo "  ⚠️  $f: $deps deps MF na interface (limite: 9)"
  fi
done

echo "============================================"
if [ "$violations" -gt 0 ]; then
  echo "❌ $violations violação(ões) encontrada(s)"
  echo "   Corrija antes de commitar ou use: git commit --no-verify"
  exit 1
fi

echo "✅ Todos os checks passaram"
exit 0
