#!/bin/bash
#
# Builds the localization command line tool from source and runs it.
#
# The tool's source lives in "Command Line Tools/Update Localizations". It is
# compiled into a throwaway directory on every run instead of committing a
# prebuilt binary. Nothing built here is distributed or needs code signing:
# the linker ad-hoc signs it, which is all macOS requires to run it locally.
#
# Usage: scripts/sync_localizations.sh <repo root>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOL_SOURCE_DIR="$REPO_ROOT/Command Line Tools/Update Localizations"

BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/wmf-sync-localizations.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT

# When run from an Xcode build phase, the environment targets the iOS SDK and
# deployment target. Strip those so the tool builds for the Mac host.
unset SDKROOT IPHONEOS_DEPLOYMENT_TARGET MACOSX_DEPLOYMENT_TARGET TARGET_DEVICE_OS_VERSION

xcrun --sdk macosx swiftc \
  -Onone \
  -module-cache-path "$BUILD_DIR/ModuleCache" \
  "$TOOL_SOURCE_DIR/main.swift" \
  "$TOOL_SOURCE_DIR/localization.swift" \
  -o "$BUILD_DIR/sync_localizations"

"$BUILD_DIR/sync_localizations" "$@"
