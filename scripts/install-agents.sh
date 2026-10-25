#!/usr/bin/env bash
# Подключает субагентов и скиллы Vadims workflow к Claude Code во всех проектах:
# симлинки ~/.claude/agents/<имя>.md → agents/<имя>.md и ~/.claude/skills/<имя> → skills/<имя>.
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

# Скиллы: каталог целиком, чтобы рядом со SKILL.md лежали его скрипты (bin/).
skills_src="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills" && pwd)"
skills_dst="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$skills_dst"
for d in "$skills_src"/*/; do
  d="${d%/}"
  name="$(basename "$d")"
  link="$skills_dst/$name"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$d" ]; then
    echo "  уже подключён скилл: $name"
  elif [ -e "$link" ] || [ -L "$link" ]; then
    echo "  ПРОПУЩЕН скилл: $link уже существует и ведёт не сюда — разберись вручную" >&2
  else
    ln -s "$d" "$link"
    echo "  подключён скилл: $name"
  fi
done
