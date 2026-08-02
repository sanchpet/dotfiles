#!/bin/sh
# Register the browser MCP server (chrome-devtools-mcp) with the PERSONAL Claude profile. Like the
# mcp-tg registration next to it, this otherwise lives only as hand-typed state under
# ~/.claude-personal and is lost the moment that profile is rebuilt or the machine is replaced.
#
# revision: 1  — bump to force a re-run after editing the intent below.
#
# Personal profile ONLY. The contours are separated by CLAUDE_CONFIG_DIR, so a --scope user
# registration made here is invisible to the work profile. Setting the variable explicitly, rather
# than inheriting whatever shell runs `chezmoi apply`, is the point: without it the registration
# lands in whichever profile happened to be active — which is exactly how this server ended up in
# the default profile and absent from the personal one until an agent went looking for it.
#
# The endpoint is fixed at the port `cometdbg` (dot_zshrc.tmpl) opens, because the server attaches
# to a browser that is ALREADY running instead of launching its own. Both halves have to agree on
# the number, so neither side gets to choose it at run time.
#
# No credentials, so unlike mcp-tg this needs no Vault and never skips for reachability.
set -eu

CONFIG_DIR="$HOME/.claude-personal"
BROWSER_URL="http://127.0.0.1:9222"

command -v claude >/dev/null 2>&1 || { echo "chrome-devtools: claude not on PATH — skipping registration"; exit 0; }
command -v npx    >/dev/null 2>&1 || { echo "chrome-devtools: npx not on PATH (node not applied yet?) — skipping"; exit 0; }

# Idempotent: already registered is the steady state, not an error.
if CLAUDE_CONFIG_DIR="$CONFIG_DIR" claude mcp list 2>/dev/null | grep -q '^chrome-devtools'; then
  echo "chrome-devtools: already registered in the personal profile"
  exit 0
fi

CLAUDE_CONFIG_DIR="$CONFIG_DIR" claude mcp add chrome-devtools \
  --scope user \
  -- npx -y chrome-devtools-mcp@latest --browser-url "$BROWSER_URL"

echo "chrome-devtools: registered. It drives a browser that is already running —"
echo "                 start one with 'cometdbg' before asking an agent to use it."
