#!/usr/bin/env bash
set -euo pipefail

SRC=".ai-setup/rules"             # updated source directory
CUR=".cursor/rules"
WIN=".windsurf/rules"
CLAUDE="CLAUDE.md"

echo "📁 Creating directories if they don't exist..."
mkdir -p "$CUR" "$WIN"

echo "🧹 Cleaning target directories..."
find "$CUR" -mindepth 1 -exec rm -rf {} + 2>/dev/null || true
find "$WIN" -mindepth 1 -exec rm -rf {} + 2>/dev/null || true

echo "📁 Preparing directories..."
mkdir -p "$CUR" "$WIN/tmp"

echo "🔎 Checking source files in $SRC:"
ls -la "$SRC"

echo "📤 Syncing Cursor (.mdc only)..."
rsync -av \
  --include='*/' \
  --include='*.mdc' \
  --exclude='*' \
  "$SRC"/ "$CUR"/

echo "📤 Syncing Windsurf (.mdc → .md)..."
rsync -av \
  --include='*/' \
  --include='*.mdc' \
  --exclude='*' \
  "$SRC"/ "$WIN/tmp"/

echo "🔄 Converting and moving for Windsurf..."
for src in "$WIN/tmp/"*.mdc; do
  mv "$src" "$WIN/$(basename "${src%.mdc}.md")"
done
rm -rf "$WIN/tmp"

echo "📄 Generating combined CLAUDE.md..."
{
  for f in "$SRC"/*.mdc; do
    echo -e "\n<!-- Source: $(basename "$f") -->"
    cat "$f"
  done
} > "$CLAUDE"

echo "✅ Sync complete! Cursor has .mdc, Windsurf has .md, and CLAUDE.md is updated."
