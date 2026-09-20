#!/bin/sh
# Install fontTools with the woff extra, which mise cannot declare.
#
# revision: 1  — bump to force a re-run after editing the version below.
#
# The `pipx:` backend drops the extra silently: `pipx:fonttools[woff]` installs plain fonttools and
# puts a shim on PATH ahead of this one, so pyftsubset exists but refuses every woff2 file with
# "No module named brotli". woff2 is compressed with brotli, so without the extra the tool cannot
# read or write the only format a web font ships in — which is the whole job here.
#
# The job: amilima card templates embed their typefaces instead of fetching them from Google, and
# an unsubset face costs a few hundred kilobytes per family. Subsetting to the alphabets a card
# actually uses is what keeps that affordable.
#
# fontTools is currently present in the mise python as a transitive dependency of another tool.
# That is accident, not declaration — it disappears the moment that tool does.
# Call the tool by its full path, never as plain `pyftsubset`. fontTools rides into the mise
# python as a transitive dependency of fb-idb, so a mise shim for pyftsubset sits ahead of
# ~/.local/bin on PATH and resolves to that copy — the one without brotli. `mise reshim` does
# not drop it. The working binary is:
#   ~/.local/share/uv/tools/fonttools/bin/pyftsubset
set -eu

command -v uv >/dev/null || { echo "uv not on PATH — mise installs it; run 'mise install' first" >&2; exit 1; }

uv tool install --force "fonttools[woff]==4.65.0"

# Prove the extra actually landed: the failure mode above is silent until the first woff2 file.
"$HOME/.local/share/uv/tools/fonttools/bin/python" -c 'import brotli' \
  || { echo "fonttools installed without brotli — the woff extra did not take" >&2; exit 1; }
