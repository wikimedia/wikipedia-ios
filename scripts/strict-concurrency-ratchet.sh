#!/bin/sh
# Compare strict-concurrency counts with the checked-in baseline.
#
# Usage: scripts/strict-concurrency-ratchet.sh [--summary FILE] [--title TEXT] BASELINE COUNTS TARGET...
#
# BASELINE  .github/strict-concurrency-baseline.json: {"targets": {"<target>": n}}
# COUNTS    the JSON output of scripts/strict-concurrency-count.sh
# TARGET    the targets to check. A target that is not in COUNTS has 0 warnings.
#
# For each target:
#   count > baseline   GitHub error annotation. The script fails.
#   count < baseline   GitHub notice annotation that asks the PR to lower the baseline.
#   count = baseline   no annotation.
# The script also fails if COUNTS has build_succeeded false, or if a target has no
# baseline entry.
#
# --summary FILE  Append a Markdown table to FILE (for example "$GITHUB_STEP_SUMMARY").
# --title TEXT    The heading of the Markdown table.
#
# Exit status: 0 if no count is above the baseline; 1 if a check fails; 2 on a usage error.

set -eu

SUMMARY=""
TITLE="Strict concurrency"

usage() {
    echo "usage: $0 [--summary FILE] [--title TEXT] BASELINE COUNTS TARGET..." >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --summary)
            [ $# -ge 2 ] || usage
            SUMMARY="$2"
            shift 2
            ;;
        --title)
            [ $# -ge 2 ] || usage
            TITLE="$2"
            shift 2
            ;;
        -h|--help) usage ;;
        -*) usage ;;
        *) break ;;
    esac
done

[ $# -ge 3 ] || usage
BASELINE="$1"
COUNTS="$2"
shift 2

for file in "$BASELINE" "$COUNTS"; do
    if [ ! -r "$file" ]; then
        echo "error: cannot read $file" >&2
        exit 2
    fi
done

exec python3 -I - "$BASELINE" "$COUNTS" "$SUMMARY" "$TITLE" "$@" <<'PYTHON'
import json
import sys

baseline_path, counts_path, summary_path, title = sys.argv[1:5]
targets = sys.argv[5:]

with open(baseline_path, encoding="utf-8") as handle:
    baseline = json.load(handle)["targets"]
with open(counts_path, encoding="utf-8") as handle:
    counts = json.load(handle)

TOP_FILES = 10
failed = False
rows = []
details = []


def annotate(level, message):
    print(f"::{level} title=Strict concurrency::{message}")


if not counts.get("build_succeeded"):
    annotate("error", "The build log has no BUILD SUCCEEDED. The counts are not complete.")
    failed = True

for target in targets:
    measured = counts.get("targets", {}).get(target, {"count": 0, "files": {}})
    count = measured["count"]
    allowed = baseline.get(target)
    if allowed is None:
        annotate("error", f"{target} has no entry in {baseline_path}. Add it with the value {count}.")
        failed = True
        rows.append((target, "missing", count, "no baseline"))
        continue
    if count > allowed:
        annotate(
            "error",
            f"{target} has {count} concurrency warnings. The baseline is {allowed}. "
            f"Remove the {count - allowed} new warning(s). Do not raise the baseline.",
        )
        failed = True
        status = f"above by {count - allowed}"
    elif count < allowed:
        annotate(
            "notice",
            f"{target} has {count} concurrency warnings. The baseline is {allowed}. "
            f"Lower the {target} entry in {baseline_path} to {count} in this PR.",
        )
        status = f"below by {allowed - count}: lower the baseline"
    else:
        status = "at baseline"
    rows.append((target, allowed, count, status))
    if measured["files"]:
        details.append((target, measured["files"]))
    print(f"{target}: {count} (baseline {allowed}, {status})")

if summary_path:
    lines = [f"## {title}", "", "| Target | Baseline | Count | Result |", "|---|---:|---:|---|"]
    lines += [f"| {target} | {allowed} | {count} | {status} |" for target, allowed, count, status in rows]
    lines.append("")
    for target, files in details:
        lines.append(f"<details><summary>{target}: files with the most warnings</summary>")
        lines.append("")
        lines.append("| File | Warnings |")
        lines.append("|---|---:|")
        for path, number in list(files.items())[:TOP_FILES]:
            lines.append(f"| `{path}` | {number} |")
        lines.append("")
        lines.append("</details>")
        lines.append("")
    with open(summary_path, "a", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")

sys.exit(1 if failed else 0)
PYTHON
