# Wikipedia iOS Continuous Integration

Our continuous integration process involves a combination of both Xcode Cloud workflows and Github Actions.

## Localizations

We have a Github Action [workflow](../.github/workflows/localization.yml) that automatically runs our localizations script whenever a Translatewiki PR is opened against the `twn` branch. The file changes made from this script are then committed and pushed up to the PR branch. More details on this process can be found in the [localization document](localization.md).

## PR Tests

Our PR unit tests are run in a GitHub Action workflow named "Run Unit Tests". This kicks off any time a PR is opened or changed against the main branch.

## UI Tests

UI-test workflow details are covered in the [UI-test GitHub Actions mapping](../WikipediaUITests/GITHUB_ACTIONS.md).

In short:
- `Run UI Tests` is the fixture-backed `WikipediaUITests` lane. It runs on nightly `repository_dispatch` and manual release-tag dispatch using the `English (Light)` configuration from the `UITests` test plan.
- `Run E2E Tests` is the live-network smoke lane. It runs on PRs targeting `main` and manual release-tag dispatch using the `English (Light, E2E)` configuration and the test identifiers in `WikipediaUITests/E2ESmokeTests.txt`.
- `Run Full UI Test Plan` is a manual release-tag lane that builds `WikipediaUITests` once and fans out `test-without-building` jobs for every checked-in `UITests.xctestplan` configuration.

#### Localization Tests - Xcode Cloud workaround 
*Note: These tweaks were needed to get our localization tests to run in Xcode Cloud. We have since moved tests to GitHub Actions, so it's possible these workarounds are no longer needed. We are keeping our steps here for posterity.*

In order to get our [localization tests](../WikipediaUnitTests/Code/TWNStringsTests.m) to run properly, some workarounds were needed to make the localization source code (files within `Wikipedia/iOS Native Localizations` and `Wikipedia/Localizations`) available in the Xcode Cloud environment.

1. We made references to source root directory dynamic, depending on if tests are running locally or within the Xcode Cloud context. This source root directory is referenced when pulling the resources referenced in `Wikipedia/iOS Native Localizations` or `Wikipedia/Localizations` for evaluations in these tests. We are using `SOURCE_ROOT_DIR` key in the unit tests Info.plist [file](../WikipediaUnitTests/Info.plist) which has value of $(SRCROOT) by default, to run locally. This key's value is then updated before tests are run in the Xcode Cloud environment, via [ci_pre_xcodebuild.sh](../ci_scripts/ci_pre_xcodebuild.sh) and our [copy_sourceroot.sh](../ci_scripts/copy_sourceroot.sh) script.
2. We added a relative symlink from `ci_scripts` to the localizations directories. First a `Wikipedia` directory was made in `ci_scripts`, then symlinks were added from that directory like this:

`ln -s ../../Wikipedia/"iOS Native Localizations" "iOS Native Localizations"`

Changes were then committed to git ([example](https://github.com/wikimedia/wikipedia-ios/pull/4507/commits/86d9f3150c2e5a021910eba0a3e21a96ad0a27e6)). 

## Deploys

GitHub Actions is the primary deploy path. Each of these is a workflow in
[.github/workflows](../.github/workflows), and each pushes its own git tag so we
know which commit a given build came from:

| Workflow | App | Scheme | Tag |
| --- | --- | --- | --- |
| V2 Deploy Design Review | Wikipedia Experimental | `Experimental` | `exp/{build number}` |
| V2 Deploy Alpha | Wikipedia Alpha | `Alpha` | `alphas/{build number}` |
| V2 Deploy Beta | Wikipedia | `Wikipedia` | `betas/{build number}` |

**These are not live yet.** The `V2` workflows are being tested alongside the
originals they replace - `Design Review`, `Internal TestFlight`,
`External TestFlight`, `App Store Submission` and `Release Wrap Up` - which are
still present and still what actually deploys. `Internal TestFlight` in
particular is still on its nightly schedule. At cutover the originals are
deleted, the `V2` prefix comes off these, and this note goes away.

`V2 Deploy Design Review` is kicked off manually by engineers as-needed. We use
that app to demonstrate implementation of a task or prototype that needs design
review, so designers can sign off before a task goes through PR review.

`V2 Deploy Alpha` builds the `Alpha` scheme, which points at various staging
server environments and has feature flags turned on for in-development testing.
It is meant to build every merge into `main`, and skips the build when the
latest commit is already tagged. That push trigger is commented out until
cutover, so for now it only runs when dispatched by hand - leaving it on would
double up with `Internal TestFlight`, which is still scheduled nightly. Runs are serialized, because the build number
comes from the highest `alphas/` tag and that tag is not pushed until the run
finishes.

`V2 Deploy Beta` builds the production app from a `release-candidate/YYYY.MM.DD`
branch. Unlike the other two it does not use the current date: dispatch it with
`mode=new` and a version to start a cycle - normally the date you plan to ship,
so a build carries the date it is meant to be released on - or with
`mode=existing` to keep building the cycle already in progress, which takes its
version from the existing branch.

A cycle is that branch plus an open Phabricator release task, and the two are
kept in lockstep. `mode=new` refuses to run while either still exists, so a
cycle has to be finished and cleaned up before the next one starts;
`mode=existing` refuses to run when there is no cycle to continue.

Before building anything, `mode=existing` checks that the cycle is in a sane
state: exactly one `release-candidate/*` branch, exactly one open release task,
and both naming the same version. Any other combination fails the run in about
a minute, naming which part is wrong, rather than partway through an archive
and upload. `V2 Release Wrap Up` deletes the branch at the end of a cycle, so a
second one generally means a wrap-up that never ran. Hotfixes are meant to
branch under `hotfix/` and get their own workflow rather than opening a second
release candidate.

Release submission and wrap-up are covered by `V2 Submit App Store`, which
submits a build already in TestFlight rather than building one, and
`V2 Release Wrap Up`.

### Xcode Cloud fallback

Xcode Cloud has equivalent workflows named "Beta Build", "Alpha Build" and
"Experimental Build". These are the fallback for when GitHub Actions is
unavailable, and they set version and build numbers and push tags using the same
prefixes as the table above, via [ci_pre_xcodebuild.sh](../ci_scripts/ci_pre_xcodebuild.sh),
[ci_post_xcodebuild.sh](../ci_scripts/ci_post_xcodebuild.sh) and
[tag_script_xcodebuild.sh](../ci_scripts/tag_script_xcodebuild.sh).

Note that these scripts match on the Xcode Cloud workflow name exactly, so a
workflow has to be named "Beta Build", "Alpha Build" or "Experimental Build" to
get a build number and tag at all - anything else falls through and is left
alone.

There is also a Github [Action](../.github/workflows/tag_latest_beta.yml) titled
"Tag Latest Beta", which moves the `latest_beta` tag to the latest commit on
`main`. It was used to trigger the old Xcode Cloud nightly build conditionally,
and is currently disabled.

## Relationship between wmf-apps-ci, GitHub Actions, and PR Status Checks

Our GitHub organization has a bot account called wmf-apps-ci which has been used for various reasons in the past. Currently for iOS, this bot account is used to make automated write commits to our repository. This happens in four instances:

1. When Xcode Cloud completes a Beta Build, Alpha Build or Experimental Build, [tag_script_xcodebuild.sh](../ci_scripts/tag_script_xcodebuild.sh) tags the commit with `betas/`, `alphas/` or `exp/{build number}` and pushes it to our remote repository using the wmf-apps-ci account. It does this with a fine-tuned personal access token set up in the wmf-apps-ci GitHub account settings, read from two environment variables in the Xcode Cloud workflow settings: `GITHUB_USERNAME` (the bot account name, `wmf-apps-ci`) and `GITHUB_PAT` (the token).

   **Xcode Cloud environment variables are per-workflow, not per-app.** Each workflow that tags needs its own copy of both variables. If either one is missing, the push URL collapses to `https://:@github.com/...` and the step fails with `remote: No anonymous write access.` followed by `fatal: Authentication failed`. That reads like an expired token but actually means an unset variable - worth checking before rotating anything.

2. When a Translatewiki PR is opened, a GitHub action runs the localizations script, commits and pushes the changes to the remote repository using the wmf-apps-ci account. It does this with the same fine-tuned personal access token as the previous point. This personal access token is set as a GitHub Actions repository secret in iOS repository GitHub Settings.

3. We have a manually-triggered GitHub action that posts a PR to increment the app version. This commit is made with the wmf-apps-ci account. It does this with the same fine-tuned personal access token as the previous point. This personal access token is set as a GitHub Actions repository secret in iOS repository GitHub Settings.

4. The V2 deploy workflows push their git tags (`exp/`, `alphas/`, `betas/` and `releases/`) and create the `release-candidate/{date}` branch using the wmf-apps-ci account, with the same personal access token, read from the APPS_BOT_TOKEN repository secret. The default `GITHUB_TOKEN` cannot be used for this: it is a GitHub App token with no Workflows permission, and the Actions `permissions:` block has no key to grant one, so it refuses to push any ref whose tree differs from the default branch under `.github/workflows/`. That token therefore needs `Workflows: read and write` alongside its other permissions.

### What happens when this token expires?

You should notice a few things:

- When a Beta Build is made, you will no longer see new `betas/{build number}` tag numbers added to the `main` branch.

- The V2 deploy workflows will build and upload to TestFlight successfully, then fail at their "Tag build" step. `V2 Deploy Beta` will also fail to push its release candidate branch.

- An Xcode Cloud Beta, Alpha or Experimental build will fail at its post-xcodebuild step. Note that nothing is distributed in that case: the tag script runs before the TestFlight post-action, so a failed tag fails the whole build and the archive never ships. This is the opposite of the GitHub Actions behaviour above, which uploads first and tags afterwards.

- When a Translatewiki PR is opened, you will no longer see the followup "Import translations from TranslateWiki" commit in the PR.

- Running the "Update App Version" GitHub action manually will probably fail.

To fix this:
1. Log into GitHub as wmf-apps-ci. The account credentials are in the 1Password iOS Team Vault. Generate a new fine-tuned token with access to the Wikipedia iOS Repository. Save this token in the 1Password iOS Team Vault in case we need it elsewhere in the future.

2. Edit each Xcode Cloud workflow that pushes tags - Beta Build, Alpha Build and Experimental Build (this can be done in Xcode). Under Environment, update the `GITHUB_PAT` variable with this new token, and confirm `GITHUB_USERNAME` is set to `wmf-apps-ci`. These variables are per-workflow, so updating one workflow does not update the others.

3. Log back into your usual GitHub account. Go to the Wikipedia iOS repository Settings. Under Secrets and variables > Actions, update the APPS_BOT_TOKEN secret with this new token.

### Why don't we commit and push with the standard GitHub token / github-actions user account?

When the commit is made by github-actions in a PR, our unit tests refuse to run. This is apparently [by design](https://github.com/peter-evans/create-pull-request/issues/48#issuecomment-537478081), to avoid unending actions loops. We switched to making repository changes via the wmf-apps-ci when we noticed our Translatewiki and Update App Version PRs were not running unit tests. 
