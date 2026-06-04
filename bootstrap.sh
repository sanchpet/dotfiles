#!/usr/bin/env bash
#
# bootstrap.sh — один command → настроенная машина.
#
#   Использование:
#     git clone <repo> dotfiles && cd dotfiles && ./bootstrap.sh
#
# Идемпотентно: безопасно запускать повторно. Слои настройки:
#   1. Homebrew      — менеджер пакетов (ставится, если нет)
#   2. brew bundle   — пакеты и приложения из Brewfile
#   3. chezmoi apply — раскладка конфигов (секреты — по выбранной стратегии)
#
# Секреты в репозиторий НЕ попадают (см. README, Decision Record по секретам).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- вывод ---
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# --- проверка платформы ---
[ "$(uname -s)" = "Darwin" ] || warn "Скрипт рассчитан на macOS; на $(uname -s) casks недоступны."

# --- 1. Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
  log "Homebrew не найден — устанавливаю (потребуется пароль sudo)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "Homebrew уже установлен ($(brew --version | head -1))"
fi

# brew в PATH текущей сессии (Apple Silicon → /opt/homebrew, Intel → /usr/local)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  command -v brew >/dev/null 2>&1 || die "brew не найден в PATH после установки."
fi

# --- 2. brew bundle ---
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
  log "brew bundle — установка пакетов из Brewfile"
  brew bundle --file="$DOTFILES_DIR/Brewfile"
else
  warn "Brewfile не найден в $DOTFILES_DIR — пропускаю установку пакетов."
fi

# --- 3. chezmoi (раскладка конфигов) ---
if command -v chezmoi >/dev/null 2>&1; then
  # source-path печатает путь по умолчанию даже если каталога нет — проверяем существование.
  chezmoi_src="$(chezmoi source-path 2>/dev/null || true)"
  if [ -n "$chezmoi_src" ] && [ -d "$chezmoi_src" ]; then
    log "chezmoi apply — раскладываю конфиги"
    chezmoi apply
  else
    warn "chezmoi установлен, но source ещё не инициализирован (нет $chezmoi_src)."
    warn "Инициализация (после выбора секрет-стратегии): chezmoi init --apply <repo-url>"
  fi
else
  warn "chezmoi не установлен — проверь, что 'brew \"chezmoi\"' есть в Brewfile."
fi

log "Готово. Машина настроена."
