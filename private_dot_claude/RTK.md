# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (cuts up to 90% of bash output)

## Meta Commands

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Explicit Usage

rtk is not hooked into Bash — no command is rewritten automatically. Prefix a command with `rtk` yourself where the filter's output refuses to look complete, which two kinds of filter manage: `rtk ls`, `rtk diff` and `rtk git status` drop presentation and keep every entry, while `rtk grep`, `rtk find` and `rtk jq` cut hard but print the true total, the number withheld and the command that recovers the rest.

Run bare whatever truncates in silence — reading files and unbounded history. `rtk cat` and `rtk git log` return a fraction with no count, no marker and no recovery path, so what they hand back reads as the whole thing.
