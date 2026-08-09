#!/bin/sh
# Register the Super Productivity MCP server with the PERSONAL Claude profile. Like the
# chrome-devtools and mcp-tg registrations next to it, this otherwise lives only as hand-typed
# state under ~/.claude-personal and is lost the moment that profile is rebuilt or the machine
# is replaced.
#
# revision: 1  — bump to force a re-run after editing the intent below.
#
# Personal profile ONLY, for the reason spelled out in the chrome-devtools script: `--scope user`
# writes into whichever profile CLAUDE_CONFIG_DIR names, so leaving it to the ambient shell is how
# a registration ends up in the wrong contour.
#
# Unpinned `@latest`, unlike mcp-tg and wolt-cli. Those two are pinned because each holds a live
# session — one authorises the whole Telegram account, the other is tied to payment methods. This
# one holds no session at all: no credentials exist in the design, the data is a local directory,
# and the blast radius of a bad release is the task list on this machine. The owner accepted the
# looser rule knowingly; it is a deliberate exception to the pinning convention, not an oversight.
#
# Two steps cannot live in code, and the script says so at the end rather than pretending otherwise:
# the plugin has to be uploaded through Super Productivity's own Settings UI, and SP >= 18.13.0
# then raises a one-time Node execution consent dialog that only a human can accept.
set -eu

CONFIG_DIR="$HOME/.claude-personal"

command -v claude >/dev/null 2>&1 || { echo "super-productivity: claude not on PATH — skipping registration"; exit 0; }
command -v npx    >/dev/null 2>&1 || { echo "super-productivity: npx not on PATH (node not applied yet?) — skipping"; exit 0; }

# Idempotent: already registered is the steady state, not an error.
if CLAUDE_CONFIG_DIR="$CONFIG_DIR" claude mcp list 2>/dev/null | grep -q '^super-productivity'; then
  echo "super-productivity: already registered in the personal profile"
  exit 0
fi

CLAUDE_CONFIG_DIR="$CONFIG_DIR" claude mcp add super-productivity \
  --scope user \
  -- npx -y super-productivity-mcp

echo "super-productivity: registered. Two manual steps remain, both inside the app:"
echo "  1. npx -y super-productivity-mcp@latest --extract-plugin"
echo "     then Settings -> Plugins -> Upload Plugin, pick plugin.zip, restart the app."
echo "  2. Accept the one-time Node execution consent dialog SP raises afterwards."
echo "  Also point Settings -> Sync at a local folder inside the vault, so the accounting"
echo "  history is restorable from a clean clone (ADR-0029, INV-1)."
