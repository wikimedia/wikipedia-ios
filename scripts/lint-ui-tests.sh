#!/bin/bash

set -euo pipefail

search_path='WikipediaUITests'

find_matches() {
  local pattern="$1"

  if command -v rg >/dev/null 2>&1; then
    rg -n --glob '*.swift' "$pattern" "$search_path" || true
  else
    grep -RInE --include='*.swift' "$pattern" "$search_path" || true
  fi
}

failed=0

appearance_pattern='XCUIDevice\.shared\.appearance|\.appearance[[:space:]]*=[[:space:]]*\.(light|dark)'
appearance_matches=$(find_matches "$appearance_pattern")

if [[ -n "$appearance_matches" ]]; then
  echo "UI tests must not set simulator appearance directly; control themes from the test plan instead."
  echo "$appearance_matches"
  failed=1
fi

language_pattern='AppleLanguages|AppleLocale|AppleTextDirection|-WMFUITestLanguageCode|\.uiTestLanguageCode'
language_allowed_files='^WikipediaUITests/(Robots|Config)/(UITestConfiguration|UITestLaunchArgument)\.swift:'
language_matches=$(find_matches "$language_pattern" | grep -vE "$language_allowed_files" || true)

if [[ -n "$language_matches" ]]; then
  echo "UI tests must not set language or locale directly; control language from the test plan instead."
  echo "$language_matches"
  failed=1
fi

exit "$failed"
