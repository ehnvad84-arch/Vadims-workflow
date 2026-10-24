#!/usr/bin/env bash
# Разворачивает Vadims workflow в проекте.
#   init.sh <project-dir>            первая установка
#   init.sh <project-dir> --update   обновить только .workflow/ (AGENTS.md и docs/ не трогает)
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dst="$(cd "${1:?usage: init.sh <project-dir> [--update]}" && pwd)"
mode="${2:-}"

say() { printf '  %s\n' "$*"; }

copy_if_absent() {  # $1 — шаблон, $2 — файл проекта
  if [ -e "$2" ]; then
    say "оставлен как есть: ${2#"$dst"/}"
  else
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    say "создан: ${2#"$dst"/}"
  fi
}

add_line() {  # добавить строку в файл, если её там ещё нет
  touch "$1"
  grep -qxF -- "$2" "$1" || printf '%s\n' "$2" >> "$1"
}

move_to_end() {  # строка-исключение (!…) работает, только если стоит после правила, которое она отменяет
  local tmp
  tmp="$(mktemp)"
  grep -vxF -- "$2" "$1" > "$tmp" || true
  printf '%s\n' "$2" >> "$tmp"
  mv "$tmp" "$1"
}

echo "Vadims workflow → $dst"

# 1. Процесс: вендорится в проект и перезаписывается при каждом обновлении.
#    Шаблоны AGENTS.md и правил сюда не кладём: в проекте живут только их заполненные версии.
rm -rf "$dst/.workflow"
mkdir -p "$dst/.workflow/templates"
cp -R "$src/WORKFLOW.md" "$src/agents" "$src/prompts" "$dst/.workflow/"
cp -R "$src/templates/PRD.md" "$src/templates/work" "$dst/.workflow/templates/"
cp "$src/scripts/feature.sh" "$src/scripts/ralph.sh" "$dst/.workflow/"
git -C "$src" rev-parse --short HEAD > "$dst/.workflow/VERSION" 2>/dev/null || echo unknown > "$dst/.workflow/VERSION"
say "обновлён: .workflow/ (версия $(cat "$dst/.workflow/VERSION"))"

if [ "$mode" = "--update" ]; then
  echo "Готово."
  exit 0
fi

# 2. Файлы проекта: создаются один раз, дальше принадлежат проекту.
copy_if_absent "$src/templates/AGENTS.md" "$dst/AGENTS.md"
for f in "$src"/templates/rules/*.md; do
  copy_if_absent "$f" "$dst/docs/rules/$(basename "$f")"
done
copy_if_absent "$src/templates/pull_request_template.md" "$dst/.github/pull_request_template.md"
mkdir -p "$dst/docs/work"

# 3. Claude Code: CLAUDE.md — тот же файл, что AGENTS.md; правила подгружаются автоматически.
if [ -e "$dst/CLAUDE.md" ] || [ -L "$dst/CLAUDE.md" ]; then
  say "CLAUDE.md уже есть — перенеси содержимое в AGENTS.md и замени его симлинком, чтобы не было двух версий"
else
  ln -s AGENTS.md "$dst/CLAUDE.md"
  say "создан: CLAUDE.md → AGENTS.md"
fi
mkdir -p "$dst/.claude"
if [ -e "$dst/.claude/rules" ] || [ -L "$dst/.claude/rules" ]; then
  say ".claude/rules уже есть — проверь, что он не дублирует docs/rules/"
else
  ln -s ../docs/rules "$dst/.claude/rules"
  say "создан: .claude/rules → docs/rules"
fi

# 4. Безопасность: .env не попадает ни в Git, ни в контекст агентов.
for f in .gitignore .cursorignore; do
  add_line "$dst/$f" ".env"
  add_line "$dst/$f" ".env.*"
  move_to_end "$dst/$f" "!.env.example"
done
add_line "$dst/.gitignore" ".workflow/*.log"
say "дополнены: .gitignore, .cursorignore"

settings="$dst/.claude/settings.json"
if [ ! -e "$settings" ]; then
  cat > "$settings" <<'EOF'
{
  "permissions": {
    "deny": ["Read(./.env)", "Read(./.env.*)"]
  }
}
EOF
  say "создан: .claude/settings.json (запрет чтения .env)"
elif command -v jq >/dev/null 2>&1; then
  tmp="$(mktemp)"
  jq '.permissions.deny = ((.permissions.deny // []) + ["Read(./.env)", "Read(./.env.*)"] | unique)' "$settings" > "$tmp"
  mv "$tmp" "$settings"
  say "дополнен: .claude/settings.json (запрет чтения .env)"
else
  say "ВНИМАНИЕ: добавь в .claude/settings.json → permissions.deny: \"Read(./.env)\", \"Read(./.env.*)\""
fi

cat <<'EOF'
Готово. Дальше:
  1. Заполни AGENTS.md (WHAT / WHY / HOW) и docs/rules/; в docs/rules/security.md отметь применимые фреймворки.
  2. Субагенты для Claude Code подключаются один раз на машину: scripts/install-agents.sh из клона Vadims workflow.
  3. Новая фича: .workflow/feature.sh <slug>
EOF
