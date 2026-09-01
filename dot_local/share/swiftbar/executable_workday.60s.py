#!/usr/bin/python3
"""workday.60s.py — SwiftBar plugin: today's working day in the menu bar.

Replaces the Apple Stopwatch, left running all day as the "am I on the clock" indicator: its
live view redraws at 30 fps and cost ~22% of a core for a number that changes once a second.
The refresh interval is encoded in the filename per SwiftBar's {name}.{time}.{ext} contract.

CONFIDENTIALITY — the constraint this is built around, not a note about it. It reads only
numeric aggregates of the day: epoch-millisecond marks, durations, counts, sums. It never
dereferences a title, note, project or tag, and renders no identifier of any kind — the daily
charge is summed over .values(), so no entity is ever bound to a name in this process. Nothing
leaves the machine, and the reader is a human's menu bar, not an agent. That is what makes it
safe on every machine, including the work one, where the Super Productivity MCP readers are
deliberately withheld. A "top task today" line would breach the contract, not extend the feature.

Interpreter is absolute /usr/bin/python3 (3.9.6): SwiftBar inherits the GUI launch environment,
where mise shims are absent, so `env python3` resolves differently here than in a terminal.
Consequence: this file stays 3.9-compatible — no `match`, no `X | None` annotations.
"""
import glob
import json
import os
import time
from datetime import date, timedelta

BACKUPS = os.path.expanduser("~/Library/Application Support/superProductivity/backups")
APP_SUPPORT = os.path.expanduser("~/Library/Application Support/superProductivity")

# A backup can be caught mid-write and parse as truncated JSON. Walk back through the sorted
# list rather than giving up — but bound the walk, or a corrupt store turns a 60-second refresh
# into a scan of the whole directory.
MAX_CANDIDATES = 5

# Liveness comes from the last tracked activity, not the backup's mtime: SP rewrites the backup
# on its own timer whether or not anything is tracked (observed 89 min apart overnight, with no
# work in them), so the file's age says nothing about the day. Slack of 15 min covers the ~5 min
# backup cadence plus a coffee.
IDLE_AFTER_S = 15 * 60

HISTORY_DAYS = 7


def hhmm(ms):
    """Epoch ms -> local HH:MM."""
    return time.strftime("%H:%M", time.localtime(ms / 1000.0))


def hm(seconds):
    """Duration -> H:MM, the shape the menu bar needs."""
    seconds = max(0, int(seconds))
    return "%d:%02d" % (seconds // 3600, (seconds % 3600) // 60)


def newest_backups():
    """Backup filenames are dated and zero-padded — lexical order is chronological."""
    return sorted(glob.glob(os.path.join(BACKUPS, "*.json")), reverse=True)


class Degraded(Exception):
    """A known, explainable absence of data — a short bar string plus a reason below it."""

    def __init__(self, bar, detail):
        Exception.__init__(self, bar)
        self.bar = bar
        self.detail = detail


def load():
    """Return the newest parseable backup's data, or raise Degraded."""
    if not os.path.isdir(APP_SUPPORT):
        # The app-support dir, not /Applications: the cask can be installed and the app never
        # launched, which is the state a freshly bootstrapped machine is in.
        raise Degraded("no SP", "Super Productivity has not run on this machine yet.")
    files = newest_backups()
    if not files:
        raise Degraded("no data", "No backups yet in %s" % BACKUPS)
    tried = files[:MAX_CANDIDATES]
    for path in tried:
        try:
            with open(path, "r") as fh:
                return json.load(fh)
        except (ValueError, OSError):
            continue
    raise Degraded("bad data", "Newest %d backup(s) all failed to parse." % len(tried))


def day_records(data, day):
    """Every per-day timeTracking record for `day`, as (scope, record) pairs.

    Three stores, for the same reason charged_ms reads three: SP flushes older timeTracking into
    the archives, and a 7-day table stopping at the flush boundary would report a real day as
    untracked. Both scopes are read, not just one: they mirror each other's marks for the same
    day, so their union is exact for the window while surviving either scope being absent.
    """
    out = []
    trackings = [data.get("timeTracking") or {}]
    for archive in ("archiveYoung", "archiveOld"):
        trackings.append((data.get(archive) or {}).get("timeTracking") or {})
    for tracking in trackings:
        for scope in ("tag", "project"):
            for days in (tracking.get(scope) or {}).values():
                rec = (days or {}).get(day)
                if isinstance(rec, dict):
                    out.append((scope, rec))
    return out


def window(records):
    """(first_mark_ms, last_mark_ms) for the day, or (None, None).

    Some records carry break counters and no marks at all, hence the per-field filter.
    """
    starts = [r["s"] for _, r in records if isinstance(r.get("s"), (int, float))]
    ends = [r["e"] for _, r in records if isinstance(r.get("e"), (int, float))]
    if not starts or not ends:
        return None, None
    return int(min(starts)), int(max(ends))


def breaks(records):
    """(count, total_ms) of breaks — the larger of the two within-scope sums.

    Break counters are recorded inconsistently: most days only one scope carries them, some days
    only the other, and a few carry different values under both. Summing the scopes would
    double-count those days; the larger scope total takes whichever one recorded the day.
    """
    per_scope = {}
    for scope, rec in records:
        count, total = per_scope.get(scope, (0, 0))
        per_scope[scope] = (count + int(rec.get("b") or 0), total + int(rec.get("bt") or 0))
    if not per_scope:
        return 0, 0
    return max(per_scope.values(), key=lambda ct: ct[1])


def charged_ms(data, day):
    """Time charged to tasks on `day`, across the live store and both archives.

    Summed over .values() — no entity id is ever bound, so no task can reach the output. If the
    newest backup ever grows past a few MB, cache this by the backup's mtime.
    """
    total = 0
    nodes = [data.get("task") or {}]
    for archive in ("archiveYoung", "archiveOld"):
        nodes.append((data.get(archive) or {}).get("task") or {})
    for node in nodes:
        for entity in (node.get("entities") or {}).values():
            try:
                total += int((entity.get("timeSpentOnDay") or {}).get(day) or 0)
            except (AttributeError, TypeError, ValueError):
                continue
    return total


def render(data):
    today = date.today().isoformat()
    records = day_records(data, today)
    start_ms, last_ms = window(records)
    if start_ms is None:
        raise Degraded("not started", "No tracked time for %s yet." % today)

    now = time.time()
    live = (now - last_ms / 1000.0) < IDLE_AFTER_S
    # While the day runs, length is now - start, so the backup cadence never shows as lag; once
    # tracking stops it freezes at the last mark, or the bar spends every evening counting hours
    # nobody worked. A finished day needs no special case tomorrow: the date key changes.
    elapsed = (now if live else last_ms / 1000.0) - start_ms / 1000.0
    glyph = "▶" if live else "⏸"
    n_breaks, break_ms = breaks(records)

    print("%s %s · %s" % (glyph, hhmm(start_ms), hm(elapsed)))
    print("---")
    print("Day started %s" % hhmm(start_ms))
    print("Last activity %s" % hhmm(last_ms))
    print("Elapsed %s" % hm(elapsed))
    print("Charged to tasks %s" % hm(charged_ms(data, today) / 1000.0))
    print("Breaks %d · %s" % (n_breaks, hm(break_ms / 1000.0)))
    print("---")

    # font=Menlo because the menu is proportional and the columns would not line up otherwise.
    print("Last %d days | font=Menlo" % HISTORY_DAYS)
    for offset in range(HISTORY_DAYS):
        day = (date.today() - timedelta(days=offset)).isoformat()
        s, e = window(day_records(data, day))
        if s is None:
            print("%s  %s  %5s | font=Menlo" % (day[5:], "—".center(11), "—"))
            continue
        # Today's row is the bar's own figure, so the table cannot contradict the line above it.
        span = elapsed if offset == 0 else (e - s) / 1000.0
        print("%s  %s→%s  %5s | font=Menlo" % (day[5:], hhmm(s), hhmm(e), hm(span)))


def main():
    try:
        render(load())
    except Degraded as err:
        print("⏱ %s" % err.bar)
        print("---")
        print(err.detail)
    except Exception as err:  # never a traceback in the menu bar, never an empty slot
        print("⏱ error")
        print("---")
        print("%s: %s" % (type(err).__name__, err))
    # Emitted whatever happened above — the dropdown must stay useful when the numbers fail — but
    # only where the app exists, so a machine without it gets no dead menu item. Deliberately a
    # different test from load()'s: an installed-but-never-launched app has no store to read and
    # is exactly the case this button is for.
    if os.path.isdir("/Applications/Super Productivity.app"):
        print("---")
        print('Open Super Productivity | bash=/usr/bin/open param1=-a param2="Super Productivity" terminal=false')


main()
