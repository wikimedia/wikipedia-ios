# UI-Test GitHub Actions Mapping

This document maps the GitHub Actions workflows to the Xcode schemes, test targets, and test-plan configurations they exercise. Keep it aligned with `.github/workflows`, `.github/actions`, `Test Plans/UITests.xctestplan`, and `WikipediaUITests/E2ESmokeTests.txt`.

## Shared CI Shape

UI Test workflows run on `macos-latest`, select Xcode `26.2`, prepare an `iPhone 16` simulator running iOS `26.2`, and build from `Wikipedia.xcodeproj`.

The UI-test suite itself is one Xcode test target:

```text
WikipediaUITests
```

The `UITests` test plan selects that target and defines the checked-in configurations:

| Configuration | Language and region | Theme | HTTP profile |
| --- | --- | --- | --- |
| `English (Light)` | `en-US` | `light` | default `fixture-strict` |
| `English (Light, E2E)` | `en-US` | `light` | `e2e` |
| `Hebrew (Sepia)` | `he-IL` | `sepia` | default `fixture-strict` |
| `German (Dark)` | `de-DE` | `dark` | default `fixture-strict` |
| `Vietnamese (Black)` | `vi-VN` | `black` | default `fixture-strict` |

`UITestConfiguration` reads the active test-plan arguments and forwards deterministic launch arguments to the app process. If the configuration does not pass `-WMFTestHTTPClientProfile e2e`, the launch defaults to `fixture-strict`.

## Workflow Map

| Workflow | File | Triggers | Scheme | Test plan/configuration | Test selection | Why it exists |
| --- | --- | --- | --- | --- | --- | --- |
| Run Unit Tests | `.github/workflows/run_unit_tests.yml` | `pull_request` to `main`, `push` to `main`, manual dispatch | `Wikipedia`, `WMFComponents`, `WMFData` matrix | Scheme defaults | Full scheme tests | PR and main-branch unit test signal for app, components, and data layers |
| Run UI Tests | `.github/workflows/run_ui_tests.yml` | `repository_dispatch` type `nightly-ui-tests`, manual dispatch from a release tag | `WikipediaUITests` | `UITests`, `English (Light)` | Full configuration | Deterministic fixture-backed UI regression signal for nightly and release-tag validation |
| Run E2E Tests | `.github/workflows/run_e2e_ui_tests.yml` | `pull_request` to `main`, manual dispatch from a release tag | `WikipediaUITests` | `UITests`, `English (Light, E2E)` | Identifiers in `WikipediaUITests/E2ESmokeTests.txt` | Small live-network smoke signal for flows where integration matters |
| Run Full UI Test Plan | `.github/workflows/run_full_ui_test_plan.yml` | Manual dispatch from a release tag | `WikipediaUITests` | Every checked-in `UITests.xctestplan` configuration | Full selected configuration per matrix job | Release-tag confidence across fixture, E2E, language, RTL, and theme configurations |
| Tag Latest Beta | `.github/workflows/tag_latest_beta.yml` | Daily schedule, manual dispatch | None | None | None | Moves `latest_beta`; dispatches nightly fixture-backed UI tests when `main` has advanced |
| Check PR and App Versions | `.github/workflows/check_versions.yml` | PR opened, reopened, labeled, unlabeled, synchronized | None | None | None | Release-label policy gate, not an XCTest lane |

## Run UI Tests

`Run UI Tests` is the fixture-backed UI-test lane. It runs when:

- `tag_latest_beta.yml` emits a `nightly-ui-tests` repository dispatch after moving `latest_beta`;
- an engineer manually dispatches the workflow from a GitHub release tag.

Manual runs verify that the selected ref is a release tag. Nightly dispatch checks out `github.event.client_payload.ref`, which is currently `latest_beta`.

This workflow runs:

```sh
xcodebuild test \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "English (Light)"
```

It uploads `WikipediaUITests-TestResults` and, on success, publishes `WikipediaUITests-coverage`.

Use this lane for deterministic UI regression coverage that should not depend on live network state.

## Run E2E Tests

`Run E2E Tests` is the live-network smoke lane. It currently runs on PRs targeting `main` and can also be manually dispatched from a release tag.

This workflow selects:

```text
UITests / English (Light, E2E)
```

That configuration passes:

```text
-WMFTestHTTPClientProfile e2e
```

The workflow reads `WikipediaUITests/E2ESmokeTests.txt`, strips comments and blank lines, and turns each remaining XCTest identifier into an `-only-testing:` argument.

It uploads `WikipediaUITests-E2E-TestResults` and, on success, publishes `WikipediaUITests-E2E-coverage`.

Use this lane only for a small set of flows where live services are part of the behavior under test. Keep broad regression coverage fixture-backed.

## Run Full UI Test Plan

`Run Full UI Test Plan` is the release-tag confidence lane. It is manual-only.

The workflow reads the selected tag's `Test Plans/UITests.xctestplan`, derives a matrix from the `configurations` array, builds `WikipediaUITests` once with:

```sh
xcodebuild build-for-testing \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -testProductsPath WikipediaUITests.xctestproducts
```

Then each matrix job downloads the archived test products and runs:

```sh
xcodebuild test-without-building \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "<matrix configuration>" \
  -testProductsPath WikipediaUITests.xctestproducts
```

Each matrix job uploads its `.xcresult`, writes a test-result summary, and publishes coverage on success.

The matrix is the checked-in configuration list. It is not a generated language by theme Cartesian product.

## Where Results Live

UI-test workflows upload `.xcresult` bundles as GitHub Actions artifacts:

| Workflow | Artifact |
| --- | --- |
| Run UI Tests | `WikipediaUITests-TestResults` |
| Run E2E Tests | `WikipediaUITests-E2E-TestResults` |
| Run Full UI Test Plan | `WikipediaUITests-FullTestPlan-<configuration>-TestResults` |

Use result bundles for failure summaries, screenshots, accessibility snapshots, and retained UI-test attachments. Prefer:

```sh
xcrun xcresulttool get test-results summary --path <bundle>.xcresult
```

before changing source code.

## Updating The Mapping

Update this document when any of these change:

- `.github/workflows/run_ui_tests.yml`
- `.github/workflows/run_e2e_ui_tests.yml`
- `.github/workflows/run_full_ui_test_plan.yml`
- `.github/actions/prepare-simulator`
- `.github/actions/test-result-summary`
- `.github/actions/coverage-summary`
- `Test Plans/UITests.xctestplan`
- `WikipediaUITests/E2ESmokeTests.txt`
- `WikipediaUITests/Config/UITestConfiguration.swift`

