#!/usr/bin/env bash
# Re-convert entries listed in pdfs/.failures-retry.txt using xelatex + Lua fixes.
set -u
export PATH="/Library/TeX/texbin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

LIST="$ROOT/pdfs/.failures-retry.txt"
[ -f "$LIST" ] || { echo "Missing $LIST"; exit 1; }

LUA="$ROOT/scripts/pandoc-fix-latex.lua"
ERR="$ROOT/pdfs/.pandoc-final.stderr.log"
FAIL2="$ROOT/pdfs/.failures-final.txt"
: > "$ERR"
: > "$FAIL2"
ok=0
bad=0
while IFS= read -r rel || [ -n "$rel" ]; do
  [ -z "$rel" ] && continue
  f="$ROOT/$rel"
  [ -f "$f" ] || { echo "skip missing: $rel"; bad=$((bad+1)); continue; }
  out="$ROOT/pdfs/${rel%.md}.pdf"
  dir=$(dirname "$rel")
  base=$(basename "$rel")
  mkdir -p "$(dirname "$out")"
  if ( cd "$ROOT/$dir" && pandoc -f markdown-raw_tex --lua-filter="$LUA" --pdf-engine=xelatex "./$base" -o "$out" ) 2>>"$ERR"; then
    ok=$((ok+1))
    echo "  OK: $rel"
  else
    echo "$rel" >> "$FAIL2"
    echo "FAIL: $rel"
    bad=$((bad+1))
  fi
done < "$LIST"

echo ""
echo "Done: $ok ok, $bad failed (see pdfs/.failures-final.txt if any)."
