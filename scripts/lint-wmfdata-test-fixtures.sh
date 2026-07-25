#!/usr/bin/env bash
set -euo pipefail

paths=("$@")
if [ "${#paths[@]}" -eq 0 ]; then
  paths=(
    "WMFData/Tests/WMFDataTests"
    "WMFComponents/Tests/WMFComponentsTests"
    "WikipediaUnitTests"
  )
fi

matches_file="$(mktemp)"
trap 'rm -f "$matches_file"' EXIT

assignment_pattern='WMFDataEnvironment\.current\.[[:alnum:]_]+[[:space:]]*=[[:space:]]*[^=]'

if command -v rg >/dev/null 2>&1; then
  rg -l --glob '*.swift' "$assignment_pattern" "${paths[@]}" || true
else
  grep -RIlE --include='*.swift' "$assignment_pattern" "${paths[@]}" || true
fi | sort -u > "$matches_file"

failed=0

while IFS= read -r file; do
  [ -z "$file" ] && continue

  case "$file" in
    *WMFDataTestFixture.swift|WikipediaUnitTests/ArticleTestHelpers.swift)
      continue
      ;;
  esac

  uses_fixture=0
  if grep -q "WMFDataTestFixture" "$file" &&
    (grep -Eq "await[[:space:]]+[[:alnum:]_]+\\.setUp\\(\\)" "$file" ||
      grep -Eq "[[:alnum:]_]+\\.withConfiguredEnvironment\\(" "$file"); then
    uses_fixture=1
  fi

  if [ "$uses_fixture" -ne 1 ]; then
    echo "error: $file mutates WMFDataEnvironment.current but does not use WMFDataTestFixture setup" >&2
    failed=1
  fi

  if ! grep -q "resetWMFDataTestState()" "$file" &&
    ! grep -Eq "[[:alnum:]_]+\\.withConfiguredEnvironment\\(" "$file"; then
    echo "error: $file mutates WMFDataEnvironment.current but does not call resetWMFDataTestState()" >&2
    failed=1
  fi
done < "$matches_file"

if [ "$failed" -ne 0 ]; then
  exit "$failed"
fi

echo "WMFData environment-mutating tests use reset fixtures."
