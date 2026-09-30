#!/bin/sh
# One-key screenshot: F13 copies a selected area to the clipboard. On the Ducky One 3 SF, Fn+PrtSc
# arrives as F13; the parameters below are what System Settings recorded when that key was pressed
# into the "Copy picture of selected area to the clipboard" shortcut (symbolic hotkey 31):
# no character (65535), key code 105 (F13), modifier mask 8388608 (function-key flag only).
#
# revision: 1  — bump to force a re-run after editing the intent below.
#
# The system reads this plist at login, so a write here shows up after the next login rather than
# immediately; a shortcut set through the System Settings pane is live at once.
set -eu

[ "$(uname -s)" = "Darwin" ] || exit 0

defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 31 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key>
    <dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array><integer>65535</integer><integer>105</integer><integer>8388608</integer></array>
    </dict>
  </dict>'
echo "screenshot: F13 copies a selected area to the clipboard"
