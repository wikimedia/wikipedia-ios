---
name: ui-test-debugger
description: Record, inspect, and diagnose failing UI tests from evidence. Use when WikipediaUITests / XCTest UI tests fail — especially intermittent or visual failures where simulator state, taps, WebView content, accessibility identifiers, fixture data, animations, locale/theme configuration, or CI-only behavior must be understood before changing code.
---

# UI Test Debugger

## Overview

Turn a Wikipedia iOS UI test failure into inspectable evidence before fixing it. The core loop is: identify the exact failing surface (scheme, test plan configuration, test method), enable visible touches, record the simulator while reproducing the failure, inspect the recording with `ffmpeg`, correlate it with the `.xcresult` attachments and logs, then make the smallest evidence-backed fix.

This project's UI tests use the **Robots pattern**. Tests describe a user journey; selectors, waits, scrolling, and screenshot plumbing live in `WikipediaUITests/Robots`. Most failures are best fixed in a robot, test method, or a fixture — not in app code. See `WikipediaUITests/README.md` and `WikipediaUITests/ROBOTS.md`.

## Project facts

- **Scheme:** `WikipediaUITests`
- **Project:** `Wikipedia.xcodeproj` (workspace embedded; no root `.xcworkspace`)
- **Test plan:** `UITests` (file `Test Plans/UITests.xctestplan`)
- **Configurations:**
  - `English (Light)` — fixture-backed, the default PR lane (`-WMFTestHTTPClientProfile fixture-strict`)
  - `English (Light, E2E)` — live networking (`-WMFTestHTTPClientProfile e2e`), narrowed to `WikipediaUITests/E2ESmokeTests.txt`
  - `Hebrew (Sepia)` — fixture-backed, RTL (`he` / `IL`)
  - `German (Dark)` — fixture-backed (`de` / `DE`)
  - `Vietnamese (Black)` — fixture-backed (`vi` / `VN`)
- **Config / launch args:** `WikipediaUITests/Config/UITestConfiguration.swift` and `UITestLaunchArgument.swift`. Never set language, locale, text direction, or simulator appearance from a test — `scripts/lint-ui-tests.sh` enforces this.
- **Shared accessibility identifiers:** `WMFComponents/Sources/WMFComponents/Utility/AccessibilityIdentifiers.swift`
- **Fixture article resources:** `WikipediaUnitTests/Fixtures/ArticleControls/<language-code>`

## Principles

- Prefer the exact failing CI run, configuration, destination, logs, screenshots, and `.xcresult` over source-only theories.
- Keep reproduction narrow while diagnosing: one failing class or a few methods, the same test-plan configuration, the same simulator runtime where possible.
- Store videos, contact sheets, exported attachments, and derived data under `/tmp/<case-name>`. Do not commit recordings or generated contact sheets.
- Do not fix from a guessed cause. First prove what the test saw: the visible state, tap target, accessibility snapshot, fixture response, timeout point, or navigation state.
- After the fix, rerun the same failing surface and record again when visual behavior was part of the diagnosis.

## Workflow

### 1. Identify the failing surface

Gather the minimum facts needed to reproduce the same failure:

```bash
git status --short
gh pr checks <PR> --watch=false
gh run view <RUN_ID> --log-failed
```

For a CI failure, download the published `.xcresult` artifact (`WikipediaUITests-TestResults` for fixture lanes, `WikipediaUITests-E2E-TestResults` for E2E) and summarize it:

```bash
xcrun xcresulttool get test-results summary --path <downloaded>.xcresult
```

Record the failing test names, the **test-plan configuration** (which decides locale, theme, and whether networking is `fixture-strict` or `e2e`), the destination/runtime, and the failure messages.

### 2. Prepare the simulator and artifact paths

Always match the simulator and OS to how CI is configured. Prefer a destination `id=` over a name/OS string once a matching simulator exists.

```bash
xcrun simctl list devices booted
mkdir -p /tmp/<case-name>/recordings /tmp/<case-name>/results /tmp/<case-name>/attachments
```

### 3. Enable visible touches

Enable touch indicators before recording so taps can be correlated with UI response:

```bash
defaults write com.apple.iphonesimulator ShowSingleTouches -bool YES
```

If touches do not appear, quit and reopen Simulator, then rerun the recording.

### 4. Record the failure while running the test

Start screen recording before launching the test. Keep the recording PID so it can be stopped cleanly.

```bash
UDID=<simulator-udid>
VIDEO=/tmp/<case-name>/recordings/failure.mp4
PIDFILE=/tmp/<case-name>/recordings/record.pid

xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$VIDEO" &
echo $! > "$PIDFILE"
```

Run the narrow failing test against the same configuration that failed. For the default fixture lane:

```bash
xcodebuild test \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "English (Light)" \
  -only-testing:WikipediaUITests/<Class>/<testMethod> \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "/tmp/<case-name>/DerivedData" \
  -resultBundlePath "/tmp/<case-name>/results/failure.xcresult" \
  -quiet
```

Swap `-only-test-configuration` to match the failing lane — `"English (Light, E2E)"`, `"Hebrew (Sepia)"`, `"German (Dark)"`, or `"Vietnamese (Black)"`. The configuration controls locale, theme, and fixture-vs-live networking, so running the wrong one will not reproduce a configuration-specific failure.

Stop the recording after XCTest exits:

```bash
kill -INT "$(cat "$PIDFILE")"
wait "$(cat "$PIDFILE")" 2>/dev/null || true
```

If the recording process is still running, poll briefly before moving on; incomplete `.mp4` files can be misleading.

### 5. Summarize the result bundle

Read the machine-readable summary before opening source files:

```bash
xcrun xcresulttool get test-results summary \
  --path /tmp/<case-name>/results/failure.xcresult
```

Robots attach screenshots with `XCTAttachment(screenshot:)` and `lifetime = .keepAlways` (see `UITestRobot.captureScreenshot`), and the test plan sets `userAttachmentLifetime: keepAlways`, so screenshots and accessibility snapshots are preserved in the bundle. List and export them:

```bash
xcrun xcresulttool get test-results attachments \
  --path /tmp/<case-name>/results/failure.xcresult \
  --test-id <test-identifier>
```

### 6. Inspect the video with ffmpeg

Start with metadata:

```bash
ffprobe -hide_banner "$VIDEO"
```

Generate contact sheets at coarse and focused intervals:

```bash
ffmpeg -y -i "$VIDEO" \
  -vf "fps=1/5,scale=360:-1,tile=4x5" \
  -q:v 2 /tmp/<case-name>/recordings/contact-5s.jpg

ffmpeg -y -ss <start-seconds> -t <duration-seconds> -i "$VIDEO" \
  -vf "fps=1/2,scale=360:-1,tile=5x6" \
  -q:v 2 /tmp/<case-name>/recordings/contact-focused.jpg
```

If `drawtext` is unavailable in the local `ffmpeg`, do not block on timestamps. Use row-major ordering and make additional focused sheets around the failure window.

Open the contact sheets or representative frames and answer:

- What was visible immediately before the failure?
- Where did the test tap, and did the app respond?
- Was the expected element absent, offscreen, tiny, covered, disabled, untranslated, or present under a different accessibility identifier or label?
- Did fixture-backed content load all required subresources, scripts, styles, images, or bridge events?
- Did the robot wait for the wrong screen, a stale element, the wrong locale (RTL in `Hebrew (Sepia)`), or the wrong theme (`Dark` / `Black` / `Sepia`)?

### 7. Correlate video, XCTest, and source

Line up the visual evidence with:

- XCTest failure time and message.
- `.xcresult` screenshots and accessibility snapshots.
- App logs and fixture/network logs.
- The **robot** that owns the failing step (`WikipediaUITests/Robots/*Robot.swift`) and the accessibility identifier it queries.
- The app surface that owns the behavior, and the shared identifier in `AccessibilityIdentifiers.swift`.

For fixture-backed (`fixture-strict`) failures, confirm the bundled resources under `WikipediaUnitTests/Fixtures/ArticleControls/<language-code>` cover both the primary API response and the secondary resources the rendered WebView references. Strict fixture mode fails the request for any unmocked subresource, which can produce a partially rendered page with broken interactions. For E2E failures, the same test runs against live networking, so flakiness there is often a real timing or availability issue rather than a fixture gap.

### 8. Fix from the observed contract

Choose the smallest idiomatic fix that matches the evidence, preferring the layer the Robots pattern intends:

- Fix the **fixture route or payload** when strict fixture mode blocked a required resource.
- Fix the **accessibility identifier or robot locator** when the UI is correct but the test contract is brittle. Prefer stable identifiers over localized visible text; assert localized strings only when localization is what's under test.
- Fix the **robot's taps, waits, or scroll strategy** when the target is present but interaction or timing is wrong. Keep this logic in the robot, not the test method.
- Fix **app behavior** only when the recording shows the user-facing behavior is actually broken.
- Avoid sleeps unless the evidence shows a real asynchronous wait contract with no better signal.

Run `scripts/lint-ui-tests.sh` after touching any UI-test helper — it rejects per-test appearance/language/locale overrides.

Keep the patch scoped. Preserve unrelated local work (e.g. existing uncommitted changes in `WikipediaUITests/`).

### 9. Validate the same path

Rerun the original failing tests against the patched build and read the summary:

```bash
xcodebuild test-without-building \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "English (Light)" \
  -only-testing:WikipediaUITests/<Class>/<testMethod> \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "/tmp/<case-name>/DerivedData" \
  -resultBundlePath "/tmp/<case-name>/results/after-fix.xcresult" \
  -quiet

xcrun xcresulttool get test-results summary \
  --path /tmp/<case-name>/results/after-fix.xcresult
```

When the first fix exposes broader configuration brittleness, rerun the narrow test across the applicable configurations (`Hebrew (Sepia)`, `German (Dark)`, `Vietnamese (Black)`, and `English (Light, E2E)`) rather than assuming the single-locale pass is enough — RTL, theme, and live-vs-fixture differences are the usual culprits.

## Final Report Checklist

Report only the evidence that matters:

- Failure recording path and any contact sheets inspected.
- The configuration that reproduced the failure.
- The observed failure behavior from the recording.
- The root cause linked to the observed behavior.
- Files changed and why (and which layer: fixture / robot / identifier / app).
- Exact validation command scope (configurations run) and result counts.
- Any remaining unvalidated scope or known CI/local differences.
