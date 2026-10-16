---
name: crash-forensics
description: Investigate a Wikipedia iOS crash from a crash report or stacktrace (TestFlight, App Store, simulator console). Locates the responsible code, explains the root cause with file:line, dates the regression via git, builds reproduction steps — including finding a real article/revision that triggers the bug through the Wikipedia APIs — and prepares a Phabricator ticket draft. Use when someone pastes a crash report, a stacktrace, a "Last Exception Backtrace", or asks to investigate a user-reported crash.
---

# Crash Forensics — Wikipedia iOS

Goal: turn a crash report into (1) a root-cause diagnosis with `file:line`, (2) a reliable repro with a real example, (3) a Phabricator ticket draft — in that order. **Do not fix anything until the reporter confirms the repro and asks for the fix.**

## 1. Triaging the report

Extract from the report, in this order of priority:

- **Exception Type / Termination Reason.** Each class is a different investigation:
  - `SIGABRT` + `Last Exception Backtrace` = uncaught NSException (the exception backtrace is what matters, not the abort one).
  - `SIGABRT` with an assertion inside a *private* UIKit selector and no app frame near the top = a UIKit invariant broken through a public API. Read what the selector really is before trusting the report's label: `-[UINavigationController _gestureRecognizedInteractiveHide:]` is the `hidesBarsOnSwipe` bar-hiding gesture, not the swipe-back gesture.
  - `EXC_BAD_ACCESS` / `SIGSEGV` = memory (over-release, use-after-free, threading) — and it can live entirely inside an Apple framework, with the app frame being only the entry point (`libfaceCore` reached through `CIDetector`; the answer was to stop using the deprecated API, PR #6164).
  - `EXC_BREAKPOINT` in a Swift frame = runtime trap (force unwrap, out of bounds, precondition).
  - `RUNNINGBOARD 0xdead10cc` = not an exception: the OS killed the app while suspended holding a file lock (SQLite in the app group). The stack shows which writer was still running, not a bug at that line.
- **The exception message**, if present (the simulator console always has it; production reports do not — infer it from the framework frame that threw: `-[UICollectionView _validateScrollingTargetIndexPath:...]` = scrollToItem with an invalid index path; `_Bug_Detected_In_Client_Of_UICollectionView_Invalid_Batch_Updates` = a batch update applied against a data source that already changed; `_AssertAutoLayoutOnAllowedThreadsOnly` = UI work off the main thread).
- **Frames from the `Wikipedia`/`WMF` binary** among the framework frames. In production they come unsymbolicated (`0x104a0e938 0x104644000 + 3975480`) — don't get stuck on that, see §2.
- **What sits above and below the app frames**: above = which system API the app called (the bug's "signature"); below = what triggered it (gesture, notification, network callback, layout). E.g. `UIGestureRecognizerTarget _sendActionWithGestureRecognizer` below = it was a tap; `NSFetchedResultsController` ← `mergeChangesFromContextDidSaveNotification:` below = a Core Data save triggered it (T436533); a background `NSManagedObjectContext` `perform` below = the code above it is not on the main thread; an Apple `dispatch_apply` worker below = the framework's own internal work.
- **The user message / report context** ("Crash on watchlist looking at revisions") — maps to a screen. To tell whether the screen is SwiftUI or legacy UIKit, look at where its code lives: modern features are in `WMFComponents/Sources/WMFComponents/Components/<Feature>/`, legacy features are in `Wikipedia/Code`. The architecture guide in `CLAUDE.md` explains the split. Remember the named screen may only be the entry point — the crash can be on a screen pushed later (watchlist → diff).
- **Check that it is the app's crash at all.** A `malloc: pointer being freed was not allocated` under XCTest, with `CoreSimulator … Runtime: iOS 26.2` in the report, was a Swift runtime bug (isolated deinit, swiftlang/swift#87316), not app code. The runtime line is the fingerprint. One runner crash also marks every in-flight test as failed, so the failed list lies — rerun before reading it.

## 2. Symbolication in practice

- **You almost never need a dSYM.** The combination (system API called + screen type + trigger) usually narrows to 1–2 candidates via grep. E.g. a crash in `scrollToItem` triggered by a tap, context "revisions" → `grep -rn "scrollToItem" Wikipedia/Code` → half a dozen hits, only one matches the context.
- When the top frame is a private UIKit selector, grepping for it finds nothing. Grep for the public API that installs it: `_gestureRecognizedInteractiveHide:` → `hidesBarsOnSwipe` → `WMFNavigationBarConfiguring`.
- If the local repro works, the simulator console gives the symbolicated stacktrace for free — it confirms the mapping (that is how T435382 went: `DiffListChangeCell.tappedLabelWithSender` → `didTapItem`).
- With a dSYM in hand (rare): `atos -o Wikipedia.app.dSYM/Contents/Resources/DWARF/Wikipedia -l <load address> <frame address>`.

## 3. Locate and understand the code

1. Grep for the system API that appears at the top of the stacktrace, scoped to the candidate area.
2. Read the whole method that makes the call plus the state it consumes (data source, view models, closures).
3. Look for the **broken invariant**: index path vs. the data source's real sections; a change set applied against counts the collection view already absorbed (two fetched-results cycles in one main-queue drain with no layout pass between them — T436533); force unwrap of optional state; a callback arriving after deinit; wrong thread. Check the related data source/delegate methods in the same file — the inconsistency is usually between two methods that assume different structures.

## 4. Archaeology: dating the regression

- `git log -L <lines>:<file>` on the invariant's code (e.g. `numberOfSections`) and `git blame` on the crashing lines. If the dates diverge (one side changed, the other stayed), you found the regression and the guilty commit.
- This answers the questions the team will ask: since when does it crash? is it 100% reproducible or a race? why did nobody see it before (rare feature, conditional path)?
- Be honest about determinism: follow the control flow and state whether **every** path crashes or only some. In T435382, the visible-cell guard always failed → a crash on 100% of taps. In T436533 it was a race between two Core Data merges — deterministic only once a unit test forced the sequence.

## 5. Building the repro

### Data conditions
Identify what the API response must contain for the UI to enter the crashing state (e.g. `type: 4/5` items with `moveInfo` in the compare). Check the corresponding fetcher (`Wikipedia/Code/*Fetcher*`) for the exact endpoint and decoding model.

Not every repro is content. For a race, the repro is a unit test that forces the sequence (T436533: `CollectionViewUpdaterCrashTests`). For a crash inside an Apple framework with no app regression, there may be no repro — say so and propose the mitigation instead of inventing steps.

### Shortest path to the screen
Check `WMF Framework/Router.swift`: the app routes many URLs straight to native screens (e.g. `Special:MobileDiff/{from}...{to}`, `index.php?diff=...&oldid=...`, `Special:History`, user talk links). If a route exists, the repro becomes a one-liner:

```
xcrun simctl openurl booted "https://en.wikipedia.org/wiki/Special:MobileDiff/{from}...{to}"
```

Always give the manual path too (what the real user did) to validate the report's scenario.

### Finding real content that triggers it
Scan Wikipedia content for the data conditions by calling **the same endpoint the app uses**:

1. Candidates: `action=query&list=recentchanges` (or `list=search`, categories, etc. as appropriate) — 200–300 items.
2. For each candidate, call the app's endpoint (e.g. `/w/rest.php/v1/revision/{from}/compare/{to}`) and filter by the condition in the JSON.
3. Python script in the scratchpad with `ThreadPoolExecutor` (~12 workers), **always with an identifying User-Agent**: `WikipediaIOSCrashRepro/1.0 (<your contact email>)`. Stop at the first ~5 hits.
4. Prefer examples by **revision ID** (permanent) over examples based on "the article's current state" (they change).

If the scan finds nothing, plan B: describe the edit that produces the condition so it can be created in a personal sandbox or on test.wikipedia.org (do not edit public wikis on your own initiative).

## 6. Deliverables (in this order, stopping between steps)

1. **Diagnosis**: root cause with `file:line`, regression commit/date, determinism, why it went unnoticed. Deliver and stop — no fix yet.
2. **Repro**: conditions + deep link + manual path + real examples verified against the API that same day.
3. **Phabricator ticket draft** when asked (Phabricator is not reachable from here — deliver it ready to paste, in English): Summary / Steps to reproduce / Expected vs Actual / Root cause / Crash signature / Proposed fix. Form: `https://phabricator.wikimedia.org/maniphest/task/edit/form/1/`, tags `iOS-app-Bugs` + `Wikipedia-iOS-App-Backlog`, proposed priority with a rationale.
4. **Fix** only after confirmation: branch `T######`, commit only the fix's files (the working tree usually has Localizable.strings noise), build before delivering, PR following `.github/pull_request_template.md` (Phabricator / Notes / Test Steps / Checklist / Screenshots). Remember to link the PR in the ticket (that cannot be done from here).

## Reference cases

**T435382 (Aug 2026, PR #6081) — the full path, a bad index.** Crash in `scrollToItem` when tapping a moved-paragraph marker in a diff. Signature `_validateScrollingTargetIndexPath` + tap trigger + "watchlist revisions" context → grep `scrollToItem` → `DiffListViewController.didTapItem` using `section: 0`, but the items had been in section 2 since the Jul 2024 redesign (`6a6fc9e357`) — `didTapItem` dated from 2019. Repro: scanning recentchanges through the compare endpoint found `moveInfo` in `Special:MobileDiff/1369045204...1370193452` (Phylum). Fix: an `enum Section` replacing the section literals.

**T436533 (Aug 2026, PR #6141) — a race, not a bad index.** `NSInternalInconsistencyException` in `CollectionViewUpdater.performBatchUpdates`, reached from `NSFetchedResultsController` after a Core Data merge. Two change cycles landed in the same main-queue drain with no layout pass between; the guard compared section counts only. Two different UIKit assertions (`Invalid_Batch_Updates` and `attempt to delete item…`) had the one cause. Repro was a unit test forcing the two cycles, not content.

**PR #6164 (T229534, Sep 2026) — a crash inside Apple code.** `SIGSEGV` in `libfaceCore` on an Apple `dispatch_apply` thread, entered through `CIDetector` face detection. No app regression; ~12 reports over four months across builds. The deliverable was not a repro but the recommendation to replace the deprecated API with Vision — which a PR already in flight did.
