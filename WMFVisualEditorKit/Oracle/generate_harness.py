#!/usr/bin/env python3
"""Generates harness.html for the VisualEditor oracle.

Resolves the transitive script dependencies of VisualEditor's document model from
the upstream checkout's build/modules.json and emits a single HTML page that loads
them in order, followed by the oracle API (oracle.js). The page is loaded into a
WKWebView by run_oracle.swift; no build step (npm/grunt) is required because the
upstream repo vendors all of its dependencies under lib/.
"""

import json
import pathlib
import sys

ORACLE_DIRECTORY = pathlib.Path(__file__).resolve().parent
UPSTREAM_DIRECTORY = ORACLE_DIRECTORY / "upstream"
MODULES_PATH = UPSTREAM_DIRECTORY / "build" / "modules.json"
OUTPUT_PATH = ORACLE_DIRECTORY / "harness" / "harness.html"

# baselibs has no incoming dependency edges in modules.json (MediaWiki provides
# these libraries at runtime), so it must be listed explicitly and first.
TARGET_MODULES = ["baselibs", "visualEditor.core.build"]


def resolve_scripts(modules, target_names):
    ordered_scripts = []
    seen_modules = set()
    seen_scripts = set()

    def visit(name):
        if name in seen_modules:
            return
        seen_modules.add(name)
        module = modules.get(name)
        if module is None:
            raise KeyError(f"Unknown module: {name}")
        for dependency in module.get("dependencies", []):
            visit(dependency)
        for entry in module.get("scripts", []):
            if isinstance(entry, dict):
                if entry.get("debug"):
                    continue
                path = entry["file"]
            else:
                path = entry
            if path not in seen_scripts:
                seen_scripts.add(path)
                ordered_scripts.append(path)

    for name in target_names:
        visit(name)
    return ordered_scripts


def main():
    modules = json.load(open(MODULES_PATH))
    scripts = resolve_scripts(modules, TARGET_MODULES)

    missing = [s for s in scripts if not (UPSTREAM_DIRECTORY / s).is_file()]
    if missing:
        print("Missing script files:", file=sys.stderr)
        for path in missing:
            print(f"  {path}", file=sys.stderr)
        sys.exit(1)

    tags = "\n".join(f'    <script src="../upstream/{path}"></script>' for path in scripts)
    html = f"""<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
<meta charset="utf-8">
<title>VE dm oracle</title>
</head>
<body>
    <script>
        window.wmfLoadErrors = [];
        window.onerror = function (message, source, line) {{
            window.wmfLoadErrors.push(message + ' @ ' + source + ':' + line);
        }};
    </script>
{tags}
    <script src="oracle.js"></script>
</body>
</html>
"""
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(html)
    print(f"Wrote {OUTPUT_PATH.relative_to(ORACLE_DIRECTORY)} with {len(scripts)} scripts")


if __name__ == "__main__":
    main()
