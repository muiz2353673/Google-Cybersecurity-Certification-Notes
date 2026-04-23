#!/usr/bin/env bash
# Re-convert entries listed in pdfs/.failures.txt (uses Lua filter to skip broken https/.txt images).
set -u
export PATH="/Library/TeX/texbin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

LIST="$ROOT/pdfs/.failures.txt"
[ -f "$LIST" ] || { echo "Missing $LIST — run convert-md-to-pdf.sh first."; exit 1; }

ERR="$ROOT/pdfs/.pandoc-retry.stderr.log"
: > "$ERR"
: > "$ROOT/pdfs/.failures-retry.txt"
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
  if ( cd "$ROOT/$dir" && pandoc --lua-filter="$ROOT/scripts/pandoc-txt-image-safe.lua" "$base" -o "$out" ) 2>>"$ERR"; then
    ok=$((ok+1))
  else
    echo "$rel" >> "$ROOT/pdfs/.failures-retry.txt"
    bad=$((bad+1))
  fi
done < "$LIST"

echo "Redone: $ok ok, $bad still bad (see pdfs/.failures-retry.txt if any)."
