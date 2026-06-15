#!/usr/bin/env bash
set -euo pipefail

if ! command -v ast-grep >/dev/null 2>&1; then
  echo "error: ast-grep is required to lint WMFData test fixture usage" >&2
  exit 1
fi

if ! command -v ruby >/dev/null 2>&1; then
  echo "error: ruby is required to parse ast-grep JSON output" >&2
  exit 1
fi

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

ast-grep run \
  --lang swift \
  --pattern 'WMFDataEnvironment.current.$PROPERTY = $VALUE' \
  --json=stream \
  "${paths[@]}" \
  | ruby -rjson -ne 'puts JSON.parse($_).fetch("file")' \
  | sort -u > "$matches_file"

failed=0

while IFS= read -r file; do
  [ -z "$file" ] && continue

  case "$file" in
    *WMFDataTestFixture.swift|WikipediaUnitTests/ArticleTestHelpers.swift)
      continue
      ;;
  esac

  uses_xctest_fixture=0
  if grep -q "WMFDataEnvironmentResettingTestCase" "$file" &&
    grep -q "try await super.setUp()" "$file"; then
    uses_xctest_fixture=1
  fi

  uses_swift_testing_fixture=0
  if grep -q "WMFDataTestFixture" "$file" &&
    grep -Eq "await[[:space:]]+[[:alnum:]_]+\\.setUp\\(\\)" "$file"; then
    uses_swift_testing_fixture=1
  fi

  if [ "$uses_xctest_fixture" -ne 1 ] && [ "$uses_swift_testing_fixture" -ne 1 ]; then
    echo "error: $file mutates WMFDataEnvironment.current but does not use WMFDataEnvironmentResettingTestCase or WMFDataTestFixture setup" >&2
    failed=1
  fi

  if ! grep -q "resetWMFDataTestState()" "$file"; then
    echo "error: $file mutates WMFDataEnvironment.current but does not call resetWMFDataTestState()" >&2
    failed=1
  fi
done < "$matches_file"

if [ "$failed" -ne 0 ]; then
  exit "$failed"
fi

echo "WMFData environment-mutating tests use reset fixtures."
