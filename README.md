# Vadims workflow

Процесс разработки с AI-агентами: **план → разработка → ревью → стейджинг → релиз → ретро**.
Работает с Claude Code и с любой другой LLM: всё описано обычными Markdown-файлами.

Сам процесс — в [WORKFLOW.md](WORKFLOW.md). Это единственный источник правды; README только объясняет, как его установить.

## Что внутри

| Путь | Что |
|---|---|
| `WORKFLOW.md` | процесс целиком: принципы, этапы и гейты, контекст, модели, субагенты, Git, безопасность |
| `agents/` | 7 субагентов: `plan-reviewer`, `backend-architect`, `ui-designer`, `frontend-developer`, `test-writer`, `code-reviewer`, `debugger` |
| `skills/` | 6 скиллов: `/office-hours`, `/qa`, `/cso`, `/careful`, `/freeze`, `/unfreeze` (методы — по gstack, см. `NOTICE.md`) |
| `prompts/` | промпт планирования (для инструментов без plan mode) и промпт итерации Ralph loop |
| `templates/` | `AGENTS.md`, правила проекта, PRD, артефакты фичи, шаблон PR |
| `scripts/` | `init.sh`, `install-agents.sh`, `feature.sh`, `ralph.sh` |

## Быстрый старт

```bash
git clone https://github.com/ehnvad84-arch/Vadims-workflow.git ~/projects/Vadims-workflow

# один раз на машину: подключить субагентов и скиллы к Claude Code (симлинки в ~/.claude/agents и ~/.claude/skills)
~/projects/Vadims-workflow/scripts/install-agents.sh

# один раз на машину: сканер конфигурации агента и браузер для /qa
npm install -g --prefix ~/.local ecc-agentshield@1.6.0
claude mcp add --scope user playwright -- npx -y @playwright/mcp@0.0.83 --browser chromium --headless --isolated
npx -y playwright@1.64.0-alpha-1790635538000 install chromium

# в каждый проект
~/projects/Vadims-workflow/scripts/init.sh /path/to/project
```

После `init.sh` заполни в проекте `AGENTS.md` (WHAT / WHY / HOW) и `docs/rules/`. Дальше:

```bash
.workflow/feature.sh <slug>                                  # новая фича: ветка + спека, план, журнал
RALPH_ALLOW='Bash(npm test:*)' .workflow/ralph.sh <slug>     # автономные итерации (Ralph loop)
```

## Что `init.sh` делает в проекте

| Путь в проекте | Что | При повторном запуске |
|---|---|---|
| `.workflow/` | копия процесса, агентов, промптов, шаблонов и скриптов | перезаписывается (`--update` обновляет только её) |
| `AGENTS.md`, `CLAUDE.md` → `AGENTS.md` | главный файл проекта; для Claude Code — симлинк | не трогается |
| `docs/rules/`, `.claude/rules` → `docs/rules` | правила проекта; Claude Code загружает их автоматически | не трогается |
| `.github/pull_request_template.md` | шаблон описания PR | не трогается |
| `.gitignore`, `.cursorignore`, `.claude/settings.json` | `.env` закрыт для Git и для агентов | дополняется |

## Как дать workflow любой LLM

- **В проекте после `init.sh`:** агент читает `AGENTS.md`, а там указан путь к `.workflow/WORKFLOW.md`. Ничего объяснять не нужно.
- **Роль субагента в другом инструменте** (Codex, Cursor, OpenCode, чат): передай файл из `agents/` как системный промпт. YAML-шапку можно игнорировать.
- **Без установки:** репозиторий приватный, поэтому веб-чаты по ссылке его не откроют. Вставь в чат содержимое `WORKFLOW.md` и попроси работать по нему. Инструменты с доступом к твоему GitHub (Claude Code, Codex через `gh`/`git`) могут клонировать репозиторий сами.

## Обновление

```bash
git -C ~/projects/Vadims-workflow pull                         # агенты в Claude Code обновятся сразу (симлинки)
~/projects/Vadims-workflow/scripts/init.sh /path/to/project --update
```

## Каталоги субагентов

Новых агентов ищем в [obra/superpowers](https://github.com/obra/superpowers), [subagents.cc](https://subagents.cc), [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) и [swan4er/vibe-agents](https://github.com/swan4er/vibe-agents). Как добавлять их без дублей и противоречий — в разделе «Субагенты» в `WORKFLOW.md`.
