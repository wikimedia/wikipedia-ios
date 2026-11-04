---
name: swift6-burn-down
description: The brief for Swift 6 language-mode migration work in the Wikipedia iOS app (phases 7–11). Load it before you fix strict-concurrency warnings, count them, verify or merge a burn-down PR, or flip a target to Swift 6 (`SWIFT_VERSION = 6.0` or `swiftLanguageModes: [.v6]`). It holds the hard rules, the count script usage, the escalation rules, and the phase layout.
---

# Swift 6 burn-down brief

Goal: every target compiles in Swift 6 language mode with complete data-race checking.
Work goes leaf-first: packages, then the WMF framework, then the app targets, then extensions and tests.
Feature branches merge into `swift6-integration`. Each phase ends with one PR from
`swift6-integration` into `main`. Marina reviews that PR. Nothing goes into `main` without her.

## Setup in a new worktree

1. Copy the git-ignored xcconfig. Builds fail without it:
   `cp /Users/marinaazevedo/wikipedia-ios/Configurations/OpenSourceDebug.xcconfig Configurations/`
2. Do not touch the main checkout, and do not touch `main`.
3. Toolchain: Xcode 27.1, Swift 6.4. The minimum iOS stays 17.6.
4. Select simulators by UDID. `OS=latest` is not reliable. List them with
   `xcrun simctl list devices available`. For a build that needs no simulator, use
   `-destination "generic/platform=iOS Simulator"`.
5. There is no `xcbeautify`. Send build output to a log file in your scratch directory, then grep the log.

## Measure with the count script

`scripts/strict-concurrency-count.sh` is the only source of truth for counts. CI, the measurer,
workers, and verifiers all use it.

```sh
DD=<scratch>/dd-strict           # must not exist yet: a fresh DerivedData
LOG=<scratch>/strict.log
xcodebuild build -scheme Wikipedia -project Wikipedia.xcodeproj \
  -destination "generic/platform=iOS Simulator" -derivedDataPath "$DD" \
  SWIFT_STRICT_CONCURRENCY=complete > "$LOG" 2>&1
scripts/strict-concurrency-count.sh "$LOG" > counts.json
```

- Output: `{"build_succeeded": bool, "targets": {"<target>": {"count": n, "files": {"<path>": n}}}}`.
  File paths are relative to the project directory (use `--root DIR` to change it).
- The script maps each file to its **target** from the `SwiftCompile ... (in target 'X')` lines.
  90 files under `Wikipedia/Code/` compile into the WMF framework, so never count by folder.
- It counts unique warnings whose message matches
  `[Ss]endable|concurren|actor|isolat|data race|main actor|nonisolated`.
  It ignores `WMF Framework/Third Party/` and warnings without a Swift file location (`<unknown>:0:`).
- Exit 1 when the log has no `BUILD SUCCEEDED`. A failed build still gives a greppable log
  with low counts. Use `--allow-failed` only to look at a failed build, never to report a count.
- The Wikipedia scheme builds WMF, the app, and the three extensions. A package scheme
  (`WMFData`, `WMFComponents`, `WMFTestKitchen`) builds that package.

Measurement rules:
- Always use a **fresh** `-derivedDataPath`. An incremental build only shows warnings for
  the files it compiles again, so the count is too low.
- Confirm `BUILD SUCCEEDED` in the log itself. Do not trust the exit code of a piped command.
- Do not edit files while a build runs. Mixed-state objects cause false link errors.
- If WMF does not compile, the app target compiles zero files. An app count of 0 can mean "not built".

Baseline (2026-11-03, `main` at `5f94964fbb` plus the one-line WMF hard-error fix):

| Target | Warnings | Files |
|---|---|---|
| WMF | 665 | 85 |
| Wikipedia | 1,844 | 255 |
| WidgetsExtension | 16 | 5 |
| NotificationServiceExtension | 15 | 1 |
| ContinueReadingWidget | 1 | 1 |
| WMFData, WMFComponents, WMFTestKitchen | 0 (also 0 errors in `.v6`) | — |

## Hard rules

- **App targets use explicit `@MainActor` only.** Never set `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
  outside WMFComponents. Default isolation gives each class an isolated deinit, and that path
  aborts on runtimes before iOS 26.5 (swiftlang/swift#87316, still open). The app supports iOS 17.6.
- **Fix preference, in this order:** value types, `@MainActor`, an `actor`, a lock box
  (the `WMFLockIsolated` pattern in `WMFData/Sources/WMFData/Utility/WMFLockIsolated.swift`).
- `@unchecked Sendable` and `nonisolated(unsafe)` only with a comment that states the invariant
  (for example: "All access goes through `lock`." or "Written once in `init`, then read-only.").
- Use `@preconcurrency` only when no other fix works. Add a comment that gives the reason,
  and confine it to one file or extension.
- **No behavior change.** Do not remove or reorder `DispatchQueue` hops. Do not add main-thread
  blocking (no new `sync` to main, no semaphores on main). Do not move work onto or off the main thread.
- For an ObjC delegate protocol that UIKit calls only on main, use an isolated conformance:
  `extension X: @MainActor P`.
- Do not convert ObjC files to Swift. Do not touch `WMF Framework/Third Party/`.
- Edit Swift structurally: match braces, and keep attributes and doc comments with their declaration.
  Do not cut multi-line Swift with a regex or line offsets.
- Edit `project.pbxproj` only with a script that asserts each replacement. Then run
  `plutil -lint Wikipedia.xcodeproj/project.pbxproj` and a successful build.
- Comments: sparse. Write one only for a reason that is not clear from the code.
- Writing (commits, comments, PR text) follows ASD-STE100: short sentences, active voice, one idea per sentence.
- Commit subject prefix: `Swift 6 (<area>): `. Trailer, exactly: `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Push your branch to `origin`. `origin` is the upstream repository; pushing branches there is correct.

## Tests

- Run xctest unit tests only on iOS 26.5 or later simulators (iOS 27.0 iPhone 17 Pro is the default).
  On iOS 18.x the xctest host aborts because of swiftlang/swift#87316. That abort is not your change.
- Per cluster PR: `xcodebuild test` for WMFData, WMFComponents, and Wikipedia on iOS 27.0.
- Per flip PR: the runtime-safety run. Run the UI test plan (`Test Plans/UITests.xctestplan`) on
  iOS 18.6, 26.3, and 27.0 simulators, before and after the change. Compare the crash reports (`.ips`).
  The UI test plan runs several configurations in sequence and state can leak between them.
  Isolate a failure with `-only-test-configuration` before you blame the change.

## Escalate, do not force

Stop and report status "escalate" to the lead if:
- A crash appears on any simulator runtime.
- A test fails only with your change.
- The fix needs a behavior change, a public API redesign in WMFData or WMFComponents,
  a Core Data model change, or an ObjC-to-Swift conversion.
- The cluster cannot reach zero without more than 3 new `@unchecked Sendable` conformances.
- A merge conflict needs a judgment call.

## Report

Every report lists: the per-target counts before and after (from the script, fresh DerivedData),
each new `@unchecked Sendable` or `nonisolated(unsafe)` with its file and invariant,
the exact commands that ran and their results (`BUILD SUCCEEDED`, test totals), and the escalations.

## Phase layout

- **Phase 7, foundation.** (1) Revive phase 6 (`swift6-phase6-wmf-framework`): merge `main`,
  resolve the conflicts, fix the WMF hard error in `ColumnarCollectionViewLayoutInfo.swift`,
  `nonisolated` style constants in `Theme.swift`. (2) Wire `Configurations/SwiftConcurrency.xcconfig`
  as the base configuration of the app-project targets. (3) This count script and this skill.
  (4) CI ratchet: a checked-in per-scheme baseline (for example `.github/strict-concurrency-baseline.json`).
  A PR fails if a count goes up. A PR that lowers a count must lower the baseline.
- **Phase 8, flip the packages.** WMFTestKitchen and WMFData to `.v6` (also `build-for-testing`).
  WMFComponents to `.v6` only after the runtime-safety run. If the flip adds aborts, keep `.v5`.
- **Phase 9, WMF framework 665 → 0, then `SWIFT_VERSION = 6.0`.** Clusters, one PR each:
  Widget (`WidgetController`), Auth (`WMFAuthenticationManager`, `WMFAccountLoginLogoutFetcher`),
  reading lists, cache stack, fetchers + `Session` + `ArticleSummaryController` +
  `ImageControllerCompletionManager`, UIKit layout and views, remainder
  (`Configuration`, `LocationManager`, `WMFArticle+Migration`).
- **Phase 10, app targets 1,844 → 0, then `SWIFT_VERSION = 6.0`** on Wikipedia, Experimental, Alpha.
  Mechanical pass first (about 15 files per PR; mark UI-adjacent protocols and helpers `@MainActor`;
  start with `TalkPageReplyComposeController`, `ReferenceShowing`,
  `ArticleTableOfContentsDisplayController`, `ViewControllerRouter`). Then the hard pass:
  isolated conformances, the off-main hotspots (`SchemeHandler`, `NotificationsCenterViewController`,
  `CollectionViewUpdater`, `PageHistoryFetcher`, `DiffController`, `ReachabilityNotifier`,
  `SavedPageSpotlightManager`, `WMFDailyGameContentSource`), and the 16 Funnel singletons.
- **Phase 11, extensions and tests.** Widgets, NotificationServiceExtension, ContinueReadingWidget,
  then WikipediaUnitTests and WikipediaUITests. Remove every `.v5` pin and every `SWIFT_VERSION = 5.0`.

Clusters that share a hot file (`Session.swift`, `project.pbxproj`) run in sequence, not in parallel.

## Roles

- **Measurer:** runs the script on a fresh build and writes the scoreboard per target and file.
- **Worker:** fixes one cluster to zero. No other target count goes up. Builds, tests, commits, pushes.
- **Verifier:** runs the count and the tests again and does not trust the worker report.
  Reviews the diff against the hard rules. Verdict: approve, request changes, or escalate.
- **Integrator:** merges approved branches into `swift6-integration` one at a time,
  merges `main` into it often, and owns `project.pbxproj` conflicts.
- **Runtime-safety tester:** for flip PRs, runs the UI test plan on iOS 18.6, 26.3, and 27.0 and compares `.ips` files.
