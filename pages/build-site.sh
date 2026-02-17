#!/usr/bin/env bash
# build-site.sh — Generate index.html from SVG artifacts and the HTML template.
#
# Usage: ./pages/build-site.sh <svg-directory> <output-path>
#
# Discovers all *.svg files in <svg-directory>, generates nav links and
# board sections, then substitutes {{BOARD_NAV}} and {{BOARD_SECTIONS}}
# in pages/template.html and writes the result to <output-path>.

set -euo pipefail

SVG_DIR="${1:?Usage: build-site.sh <svg-dir> <output-path>}"
OUTPUT="${2:?Usage: build-site.sh <svg-dir> <output-path>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/template.html"

if [ ! -f "$TEMPLATE" ]; then
  echo "Error: template not found at $TEMPLATE" >&2
  exit 1
fi

# Collect SVG files (sorted alphabetically by board name)
mapfile -t SVG_FILES < <(find "$SVG_DIR" -name '*.svg' -type f | sort)

if [ ${#SVG_FILES[@]} -eq 0 ]; then
  echo "Error: no SVG files found in $SVG_DIR" >&2
  exit 1
fi

# Write nav and sections to temp files (avoids awk -v limits with large SVGs)
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
NAV_FILE="$TMPDIR/nav.html"
SECTIONS_FILE="$TMPDIR/sections.html"

: > "$NAV_FILE"
: > "$SECTIONS_FILE"

for svg_file in "${SVG_FILES[@]}"; do
  board="$(basename "$svg_file" .svg)"
  # Capitalize words: tornblue -> Tornblue, my_board -> My Board
  display_name="$(echo "$board" | sed 's/_/ /g; s/\b\(.\)/\u\1/g')"

  echo "    <a href=\"#${board}\">${display_name}</a>" >> "$NAV_FILE"

  {
    echo "    <section id=\"${board}\">"
    echo "      <h2>${display_name}</h2>"
    echo "      <div class=\"svg-container\">"
    cat "$svg_file"
    echo "      </div>"
    echo "    </section>"
  } >> "$SECTIONS_FILE"
done

# Build output directory if needed
mkdir -p "$(dirname "$OUTPUT")"

# Substitute placeholders line by line, inserting file contents at markers
while IFS= read -r line; do
  case "$line" in
    *'{{BOARD_NAV}}'*)     cat "$NAV_FILE" ;;
    *'{{BOARD_SECTIONS}}'*) cat "$SECTIONS_FILE" ;;
    *)                      printf '%s\n' "$line" ;;
  esac
done < "$TEMPLATE" > "$OUTPUT"

echo "Built $OUTPUT with ${#SVG_FILES[@]} board(s)"
