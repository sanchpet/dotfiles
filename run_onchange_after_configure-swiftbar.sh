#!/bin/sh
# Point SwiftBar at the plugin directory this repo owns, so the choice is declared rather than
# clicked. SwiftBar has no config file: the folder lives only in its preferences, and on first
# launch it blocks behind a "choose a plugin folder" dialog until a human answers.
#
# revision: 1  — bump to force a re-run after editing the intent below.
#
# This is the repo's first `defaults write`, so the reason it is safe to poke this particular key:
# `PluginDirectory` is a plain String in `UserDefaults.standard` (SwiftBar/PreferencesStore.swift
# — `case PluginDirectory`, read back as `as? String`, tilde-expanded at use), not a
# security-scoped bookmark, and the app carries no app-sandbox entitlement. So the value a human
# would pick with the folder panel and the value written here are the same value.
#
# Ordering is what makes this work without a restart: bootstrap applies dotfiles (step 7) before
# `brew bundle` (step 9), so on a fresh machine the key is already right the first time SwiftBar
# ever runs, and the dialog never appears.
#
# A dedicated directory, not ~/.local/bin: SwiftBar walks its plugin folder RECURSIVELY and treats
# every non-hidden, non-.json file it finds as a plugin to execute (PluginManger.swift,
# getPluginList). Pointed at ~/.local/bin it would run `cleanup`, `updates` and `age-archive` on
# every refresh.
#
# The path is duplicated — here and as the chezmoi source dir dot_local/share/swiftbar/. Nothing
# detects a rename of one without the other; the symptom would be an empty SwiftBar menu.
set -eu

[ "$(uname -s)" = "Darwin" ] || exit 0

DOMAIN=com.ameba.SwiftBar
PLUGIN_DIR="$HOME/.local/share/swiftbar"

mkdir -p "$PLUGIN_DIR"

current="$(defaults read "$DOMAIN" PluginDirectory 2>/dev/null || true)"
if [ "$current" = "$PLUGIN_DIR" ]; then
  echo "swiftbar: plugin directory already set to $PLUGIN_DIR"
  exit 0
fi

defaults write "$DOMAIN" PluginDirectory -string "$PLUGIN_DIR"
echo "swiftbar: plugin directory set to $PLUGIN_DIR"

# A running app owns its in-memory preferences and writes them back on the next change, which
# would undo this. Seeding before first launch is the case that matters; when the app is already
# up, say so instead of pretending the write took effect.
if pgrep -x SwiftBar >/dev/null 2>&1; then
  echo "swiftbar: SwiftBar is running — quit and reopen it for the new plugin directory to take"
fi
