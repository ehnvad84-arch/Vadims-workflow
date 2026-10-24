#!/usr/bin/env bash
# Подключает субагентов Vadims workflow к Claude Code во всех проектах:
# симлинки ~/.claude/agents/<имя>.md → agents/<имя>.md этого репозитория.
# Источник один: git pull в клоне обновляет агентов везде, копий в проектах нет.
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")/../agents" && pwd)"
dst="${CLAUDE_AGENTS_DIR:-$HOME/.claude/agents}"
mkdir -p "$dst"

for f in "$src"/*.md; do
  name="$(basename "$f")"
  link="$dst/$name"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$f" ]; then
    echo "  уже подключён: $name"
  elif [ -e "$link" ] || [ -L "$link" ]; then
    echo "  ПРОПУЩЕН: $link уже существует и ведёт не сюда — разберись вручную, чтобы не было двух версий" >&2
  else
    ln -s "$f" "$link"
    echo "  подключён: $name"
  fi
done
