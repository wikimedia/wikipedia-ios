#!/bin/sh
# Count strict-concurrency warnings per target in an xcodebuild log.
#
# Usage: scripts/strict-concurrency-count.sh [--allow-failed] [--root DIR] LOG
#
# Build the log from a fresh -derivedDataPath with SWIFT_STRICT_CONCURRENCY=complete.
# An incremental build only shows warnings for the files it compiles again.
#
# Output (stdout), JSON:
#   {"build_succeeded": bool,
#    "targets": {"<target>": {"count": n, "files": {"<repo-relative path>": n}}}}
#
# The script maps each Swift file to its target from the
# "SwiftCompile <arch> <variant> <files...> (in target 'X' from project 'Y')" lines.
# Some files under Wikipedia/Code/ compile into WMF, so a folder filter gives wrong counts.
# It counts unique warnings (file, line, column, message) whose message matches the
# concurrency vocabulary. The two architectures of a simulator build repeat each
# warning; the count includes each warning one time only.
# It matches the vocabulary against the message only, not the path
# ("TwoFactor" contains "actor").
# It does not count files in "WMF Framework/Third Party/", or warnings without
# a Swift file location ("<unknown>:0:").
#
# --root DIR      Make file paths relative to DIR. Default: the directory that
#                 the SwiftCompile tasks "cd" into (the project directory).
# --allow-failed  Print the counts and exit 0 when the log has no "BUILD SUCCEEDED".
#
# Exit status: 0 on success; 1 if the log has no "BUILD SUCCEEDED" (the JSON is
# still printed); 2 on a usage error.

set -eu

ALLOW_FAILED=0
ROOT=""
LOG=""

usage() {
    echo "usage: $0 [--allow-failed] [--root DIR] LOG" >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --allow-failed) ALLOW_FAILED=1 ;;
        --root)
            [ $# -ge 2 ] || usage
            ROOT="$2"
            shift
            ;;
        -h|--help) usage ;;
        -*) usage ;;
        *)
            [ -z "$LOG" ] || usage
            LOG="$1"
            ;;
    esac
    shift
done

[ -n "$LOG" ] || usage
if [ ! -r "$LOG" ]; then
    echo "error: cannot read log: $LOG" >&2
    exit 2
fi

exec python3 -I - "$LOG" "$ALLOW_FAILED" "$ROOT" <<'PYTHON'
import collections
import json
import re
import sys

log_path, allow_failed, root = sys.argv[1], sys.argv[2] == "1", sys.argv[3]

VOCABULARY = re.compile(r"[Ss]endable|concurren|actor|isolat|data race|main actor|nonisolated")
EXCLUDED = "WMF Framework/Third Party/"
TASK_SUFFIX = re.compile(r" \(in target '([^']*)' from project '[^']*'\)$")
SWIFT_COMPILE = re.compile(r"^SwiftCompile \S+ \S+ (.*)$")
UNESCAPED_SPACE = re.compile(r"(?<!\\) ")
WARNING = re.compile(r"^(/.+?\.swift):(\d+):(\d+): warning: (.*)$")
GROUP_SUFFIX = re.compile(r" \[#[A-Za-z0-9]+\]$")


def normalize(path):
    # /tmp and /var are symlinks into /private on macOS. Tools print both forms.
    for prefix in ("/private/tmp/", "/private/var/"):
        if path.startswith(prefix):
            return path[len("/private"):]
    return path


def unescape(token):
    return re.sub(r"\\(.)", r"\1", token)


file_targets = collections.defaultdict(set)
cd_dirs = collections.Counter()
build_succeeded = False
warnings = []  # (target from the enclosing task, path, line, column, message)

current_target = None
in_swift_compile = False

with open(log_path, encoding="utf-8", errors="replace") as log:
    for raw in log:
        line = raw.rstrip("\n")
        if "BUILD SUCCEEDED" in line:
            build_succeeded = True

        # A task header starts at column 0 and ends with the target suffix.
        task = TASK_SUFFIX.search(line)
        if task and not line.startswith(("/", " ", "<")) and ": warning: " not in line:
            current_target = task.group(1)
            compile_line = SWIFT_COMPILE.match(line[: task.start()])
            in_swift_compile = compile_line is not None
            if compile_line:
                for token in UNESCAPED_SPACE.split(compile_line.group(1)):
                    if token.startswith("/") and token.endswith(".swift"):
                        file_targets[normalize(unescape(token))].add(current_target)
            continue

        if in_swift_compile and line.startswith("    cd /"):
            cd_dirs[normalize(line[len("    cd "):].strip())] += 1
            in_swift_compile = False
            continue

        match = WARNING.match(line)
        if match:
            path, row, column, message = match.groups()
            message = TASK_SUFFIX.sub("", message)
            message = GROUP_SUFFIX.sub("", message)
            if VOCABULARY.search(message):
                warnings.append((current_target, normalize(path), row, column, message))

if not root and cd_dirs:
    root = cd_dirs.most_common(1)[0][0]
root = normalize(root.rstrip("/")) + "/" if root else ""


def relative(path):
    return path[len(root):] if root and path.startswith(root) else path


unique = set()
for task_target, path, row, column, message in warnings:
    if EXCLUDED in path:
        continue
    targets = file_targets.get(path, set())
    if len(targets) == 1:
        target = next(iter(targets))
    elif task_target in targets:
        # The file compiles into more than one target. Use the task that printed it.
        target = task_target
    elif task_target:
        target = task_target
    else:
        target = "(unattributed)"
    unique.add((target, path, row, column, message))

counts = collections.defaultdict(collections.Counter)
for target, path, _row, _column, _message in unique:
    counts[target][relative(path)] += 1

result = {
    "build_succeeded": build_succeeded,
    "targets": {
        target: {
            "count": sum(files.values()),
            "files": dict(sorted(files.items(), key=lambda item: (-item[1], item[0]))),
        }
        for target, files in sorted(counts.items())
    },
}
json.dump(result, sys.stdout, indent=2)
sys.stdout.write("\n")

if not build_succeeded:
    sys.stderr.write("error: the log has no \"BUILD SUCCEEDED\". The counts are not complete.\n")
    if not allow_failed:
        sys.exit(1)
PYTHON
