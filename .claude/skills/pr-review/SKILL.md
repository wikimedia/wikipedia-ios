---
name: pr-review
description: Review a Wikipedia iOS pull request or branch the way this team reviews — triage findings against the Phabricator ticket and the diff, check the repo-specific bug patterns below, preview every comment before anything is posted, then post only the comments the user picks as inline GitHub review comments. Also handles re-reviews after the author pushes. Use when someone says "review PR 6369", "code review <PR URL>", "review this branch", "re-review", "check if the PR was updated", or asks whether to approve a PR.
---

# PR Review — Wikipedia iOS

Goal: give the user a short, ranked list of real problems in the PR, so that they can decide what to post. The user owns the review. Claude finds, checks and drafts. The user picks, and Claude posts only what the user picks.

This skill comes from about 75 reviews of this repo (Aug–Nov 2026). The checklist in section 4 lists the bugs that those reviews found, and the bugs that they missed.

## 1. Rules

- **Read only.** Do not edit, commit, push or switch the user's branch. Read the PR head with `gh pr diff`, `git fetch origin pull/<N>/head:pr-<N>` plus `git show`, or a worktree. Fix code only when the user asks for fixes, and only on the user's own PR.
- **Post nothing until the user says so.** Show a preview first. "Review it" does not mean "post it".
- **Default review state is comment-only.** Use "request changes" or "approve" only when the user says so.
- **Write in ASD-STE100 Simplified Technical English.** Short sentences, active voice, no metaphors, about a 5th-grade reading level. Do not label comments "nit".

## 2. Collect the context before you review

1. `gh pr view <N> --json title,body,baseRefName,headRefName,author,commits,files,reviews,comments,mergeable,mergeStateStatus`. Diff against the PR's own base (it can be a `release-candidate/*` branch, not `main`). For a local branch with no PR, diff `main...HEAD`.
2. **The requirements.** Find the Phabricator ticket (`T\d+` in the title, branch or body). Read it with `curl -s "https://phabricator.wikimedia.org/api/maniphest.search" -d 'constraints[ids][0]=<id>'` or the web page. Read the PR's test steps too. The ticket, a PM decision and the test steps overrule a finding: do not report intended behavior as a bug.
3. **Existing comments.** Read Copilot's and the other reviewers' inline comments: `gh api repos/wikimedia/wikipedia-ios/pulls/<N>/comments`. Do not repeat them. Copilot often finds lifetime, `try?` and concurrency bugs. If you agree with one of its comments, say so in the preview and do not post a copy.
4. **Branch freshness.** Check `mergeStateStatus` and whether the head is behind the base. When it is, suggest a short general comment: "Please merge the latest main." Do not invent a reason for it.

## 3. Find the problems

- Run the `code-review` skill at level `high` on the PR (`/code-review high <N>`) for the first pass when it is available. Then filter its findings with the rules in this section and section 5. Without it, read every changed hunk and the callers of each changed symbol yourself.
- **Only lines the PR changes.** A bug that also exists on the base branch is not a finding for this PR. List it separately at the end as "existing bug, not from this PR", or leave it out.
- **Check each finding before you report it.** Read the caller. Trace the value. Compile a small sample when the behavior of the language is the question. When the user asks, build, run the unit tests, and run the app on the simulator (see the `run` skill and CLAUDE.md "Build and Test"). Mark a finding "not confirmed" when you could not check it.
- **Ask "does the PR do what the ticket asks?"** Missing requirements are findings too (category `incomplete-implementation`).
- **Check that the PR description is still true.** After later commits, test steps and descriptions often describe a design that is gone. QA then follows steps that cannot work.

## 4. Checklist: bugs found in this repo before

### Async work, lifetimes and re-entry
- An `actor` is re-entrant at every `await`. A "check, then insert" or "check cancellation, then save" across an `await` can run twice, or save after a cancel. Look at `await context.perform` and persist steps that follow `Task.checkCancellation()`.
- Cancellation is cooperative. Code after the last check still writes. A cancelled refresh can still set `@Published` state (for example `isVisible = false`) after a newer refresh set it.
- A `Task` that is not stored cannot be cancelled when the screen closes.
- Buttons stay enabled while an async action runs. A double tap on Done calls the completion two times, and the coordinator pops two screens.
- After an `await`, the screen can be gone. Check that `presentedViewController` is still the expected controller before you present on it.
- A weak reference in a queued draw or callback can be released early in Release builds only.
- `try?` on a save, then continue as if it succeeded. The UI closes and the source of truth changes, but nothing was saved.
- A timeout that cancels a task, then awaits `task.value`, still waits for calls that ignore cancellation (for example `performDecodableGET`).
- Network requests that do not depend on each other run one after another inside a time budget. Use a `TaskGroup`.

### UIKit lifecycle and presentation
- `viewWillDisappear` with `isMovingFromParent` is also true for an interactive Back swipe that the user cancels. Use `viewDidDisappear` for "the user left".
- `viewWillDisappear` runs only on the top controller of a navigation stack. A sheet that is dismissed with another screen on top does not call it on the root.
- `viewDidAppear` impressions log again on each return. Check that a "log if needed" closure has the guard that its name promises.
- `.overFullScreen` does not take `supportedInterfaceOrientations` from the presented controller. `WMFComponentNavigationController` already has `forcePortrait`.
- `overrideUserInterfaceStyle = .light` does not change `WMFAppEnvironment.current.theme`. Colors from the app theme (tints, nav bar appearance, `theme.colors.link` on alerts) stay dark.

### SwiftUI and WMFComponents
- `WMFFont.for(...)` ignores `.dynamicTypeSize(...)` caps. Use `WMFFont.for(_:sized:)`. A cap modifier affects only children.
- A fixed `compatibleWith: .large` font on a button stops Dynamic Type. `CapsuleButtonStyle` has a fixed 46 pt height and clips large or two-line titles.
- `GeometryReader` has no intrinsic height and collapses in a `List` row or a self-sizing `VStack`.
- An asset without `"template-rendering-intent": "template"` ignores `.foregroundColor`.
- An `AttributedString` with its own foreground color overrides `.foregroundColor`.
- `@ObservedObject var appEnvironment` that nothing reads re-renders the view on each theme change.
- Modifiers that do nothing: `.padding(.top, 0)` in a `VStack(spacing: 0)`, a branch that sets `titleView = nil` when nothing set it. Removing `.padding(.bottom, 8)` puts buttons on the edge on devices without a bottom safe area (iPhone SE).
- Two flexible views (`Spacer()` and `.frame(maxHeight: .infinity)`) share the free height, so the button floats up on tall screens.
- Removing `.scrollPosition(id:)` breaks code that moves the pager by setting the ID, and VoiceOver paging.
- A computed property that builds a constant gradient or array on each `body` evaluation.

### Accessibility and localization
- Two conditional buttons (Submit, then Next) remove the VoiceOver-focused element. Check on a device. The Simulator has no VoiceOver.
- `Image(uiImage:)` inside a button label needs `.accessibilityHidden(true)`.
- State that only icons show (correct/incorrect dots) needs an `accessibilityValue`.
- Directional images need `language-direction` variants or `.flipsForRightToLeftLayoutDirection`.
- `uppercased()` ignores the language (Turkish İ, Greek accents). Use `localizedUppercase` or `uppercased(with:)` with the content's locale.
- Error `localizedDescription`, or an enum that conforms to `LocalizedError` with no `errorDescription`, shows English or generic text to users.
- A literal year (`2026`) in strings or URLs that the next campaign reuses.

### WMFData, Core Data and the API
- MediaWiki returns HTTP 200 with an `errors` body. A decoder that reads only `query` turns the error into an empty success. The `errors` array needs `errorformat=html` in **every** parameter dictionary.
- An object inserted into the context before `try? encode` stays in the context as an orphan row and gets saved.
- Merge policies that differ between methods that write the same entity.
- Two rows that point at one `CDPage` through a to-one inverse (titles `Foo_bar` and `Foo bar`). Deduplicate after normalizing the title.
- Fetches with no `fetchLimit` that load a year of page views to keep 20.
- The same report fetched and decoded from Core Data several times on the main thread. Build it once and pass it.
- Display titles (`normalizedForDisplay`, precomposed Unicode) used to rebuild a database title.
- Comparison of sets as ordered arrays (deselect and reselect looks like a change).
- Lists merged per language one after another instead of sorted by date.

### Analytics (TestKitchen / instruments)
- The same `action`, `actionSource` and `elementId` for two different actions (save and unsave).
- One surface logs `actionSource` in two spellings (`"EmptyForYouCard"` and `"feed_empty"`), so impression and click cannot join.
- Impression deduplication that keeps only the last key logs again on scroll back.
- A funnel stopped in `viewWillDisappear` ends when the user opens an article from it.
- Logging the old value (the language switched away from) instead of the new one.
- A changed logging ID for existing events (for example `""` to `"end"`) that the PR does not say.
- A new tap target with no click event, when the analytics spec covers that screen.

### Tests and CI
- A new branch of code with no test. The fixture JSON does not contain the new fields, so the new path never runs.
- Tautological tests that compare a wrapper to the call it wraps.
- Assertions that pass only when the simulator locale is English.
- `waitUntil` loops with no timeout hang the suite until the CI job timeout. Race them against `Task.sleep`.
- Hand-written lists of enum cases in tests. Make the enum `CaseIterable`.
- Tests that set `WMFDataEnvironment.current` without `WMFDataTestFixture` fail `scripts/lint-wmfdata-test-fixtures.sh`. The lint matches only `withConfiguredEnvironment(`, not the trailing-closure form.
- Controllers that read `WMFDataEnvironment.current` stores in tests that should inject them. Other suites swap and release those stores.
- Workflows: a failed early step skips later steps through the implicit `success()`. A count or gate that passes when the scheme was not compiled at all.
- A test target that no longer compiles after a merge from main (a new required init parameter).

### Repo rules (CLAUDE.md)
- Callbacks to coordinators typed `@MainActor @Sendable () -> Void`.
- Icons through `WMFIcon` / `WMFSFSymbolIcon`. Colors through `WMFColor` and `WMFTheme`. Fonts through `WMFFont`.
- No Objective-C (`.m`) code or helpers used from WMFComponents or WMFData.
- `@unchecked Sendable` and `nonisolated(unsafe)` need a comment that is still true.
- No new `DispatchQueue` or completion handlers in new code.
- Removing a `WMFLocalizedString` leaves translations in `Wikipedia/Localizations/*.lproj`, and `TWNStringsTests` fails on plural orphans.
- Every Core Data model change is a new model version with a migration test.
- Few comments. No doc comment that only repeats the name. Delete commented-out code. Replace literals such as content group kind `3` with the enum case.
- Dead code left behind after a refactor (a helper with no caller, a branch that cannot run).

## 5. What is not a finding

- Behavior that the ticket, a PM decision or the test steps ask for.
- Product tradeoffs. Ask them as questions to the user, not as bugs.
- Bugs that exist on the base branch (list them apart, see section 3).
- Code in other features or slides that the PR does not touch. On Year in Review slide tickets, review only that slide.
- A suggestion that breaks an architecture rule, for example reuse of an Objective-C helper from a package.
- Style-only remarks when the user asked for "high and medium only".

## 6. Preview format

Show this in chat. Do not post.

1. One line: what the PR does, and whether it does what the ticket asks.
2. A numbered table, most severe first: `#`, severity (high / medium / low), `file:line`, one-line summary, "in diff" yes/no, "confirmed" yes/no.
3. For each finding:
   - The problem in two or three STE sentences.
   - A concrete failure scenario: what the user does, and what goes wrong.
   - The code snippet from the diff (a few lines). The user cannot click into the PR's diff from the local checkout, so show the code here.
   - A suggested fix. Use a GitHub ```` ```suggestion ```` block when the fix is a small change to the commented lines.
4. Separate short lists: "Copilot already raised", "existing bugs, not from this PR", "questions for product".
5. A recommendation: approve, comment, or request changes, with one sentence why.

Then stop and wait for the user to choose, for example "post 1–3", "post all but the low ones", "request changes".

## 7. Posting

Post the comments the user picked as one review with inline comments:

```bash
gh api repos/wikimedia/wikipedia-ios/pulls/<N>/reviews --method POST --input review.json
```

`review.json` holds `commit_id` (the PR head SHA), `event` (`COMMENT` unless the user said `REQUEST_CHANGES` or `APPROVE`), an optional short `body`, and `comments: [{path, line, side: "RIGHT", body}]`. Use `start_line` for a multi-line comment. The `line` must be a line in the PR diff. Otherwise GitHub rejects the whole review. Write the file to the scratchpad, not the repo.

Each comment body: the problem, the failure scenario, and the fix or a `suggestion` block. No "nit" label. No AI attribution line. After posting, give the user the review URL.

## 8. Re-review

When the user asks "was the PR updated?" or "re-review":

1. Find your last review and its commit (`gh api .../pulls/<N>/reviews`). List the commits after it. Ignore merge commits from main.
2. Give a status table for each earlier comment: fixed (with the commit), answered (quote the author's reply in a few words), or still open. Check the reply. If the author is right, say that the comment was wrong.
3. Review only the new changes, with the same rules. Show a preview again.
4. Report the CI state (`gh pr checks <N>`).

## 9. Manual test steps

When the user asks for test steps, give one simple numbered list for the PR. Cover only what the PR changes. Leave out existing bugs. State the device or setting each step needs (VoiceOver on device, Dynamic Type AX sizes, dark theme, RTL language, iPad, iPhone SE).
