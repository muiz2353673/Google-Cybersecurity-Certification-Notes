#!/usr/bin/env bash
# Convert all .md under repo root to parallel tree under ./pdfs/ (Pandoc + pdflatex).
# Run from repository root, or: bash scripts/convert-md-to-pdf.sh
set -u
export PATH="/Library/TeX/texbin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

OUT_ROOT="$ROOT/pdfs"
LOG="$OUT_ROOT/.conversion.log"
ERR="$OUT_ROOT/.pandoc.stderr.log"
FAIL="$OUT_ROOT/.failures.txt"
mkdir -p "$OUT_ROOT"
: > "$FAIL"
: > "$ERR"
{
  echo "=== $(date) ==="
  echo "ROOT=$ROOT"
} >> "$LOG"

total=0
ok=0
while IFS= read -r -d '' f; do
  rel="${f#./}"
  [ -z "$rel" ] && continue
  out="$OUT_ROOT/${rel%.md}.pdf"
  total=$((total + 1))
  dir=$(dirname "$f")
  base=$(basename "$f")
  mkdir -p "$(dirname "$out")"
  # Re-run failed files with: scripts/convert-md-failures-pdf.sh
  if ( cd "$dir" && pandoc "$base" -o "$out" ) 2>>"$ERR"; then
    ok=$((ok + 1))
  else
    echo "$rel" >> "$FAIL"
  fi
  if (( total % 150 == 0 )); then
    echo "Progress: $total files, $ok ok ($(date +%H:%M:%S))" | tee -a "$LOG"
  fi
done < <(find . -name '*.md' -not -path './pdfs/*' -not -path './.git/*' -print0)

{
  echo "=== done $(date) ==="
  echo "Total: $total  OK: $ok  Failed: $((total - ok))"
} | tee -a "$LOG"
echo "Log: $LOG"
echo "Pandoc stderr: $ERR"
echo "Failed list: $FAIL"

# Non-zero if any file failed (for automation); ok count is in log.
[ "$ok" -eq "$total" ]
exit $?
