# Wikipedia iOS Continuous Integration

Our continuous integration process involves a combination of both Xcode Cloud workflows and Github Actions.

## Localizations

We have a Github Action [workflow](../.github/workflows/localization.yml) that automatically runs our localizations script whenever a push is made to the `twn` branch. The file changes made from this script are then committed and pushed up to the PR branch. More details on this process can be found in the [localization document](localization.md).

## PR Tests

Our PR unit tests are run in a GitHub Action workflow named "Run Unit Tests". This kicks off any time a PR is opened or changed against the main branch.

## UI Tests

UI-test workflow details are covered in the [UI-test GitHub Actions mapping](../WikipediaUITests/GITHUB_ACTIONS.md).

In short:
- `Run UI Tests` is the fixture-backed `WikipediaUITests` lane. It runs daily at 2:00UTC as well as manual dispatch, using the `English (Light)` configuration from the `UITests` test plan.
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

These are the live deploy path. The originals they replace - `Design Review`,
`Internal TestFlight`, `External TestFlight`, `App Store Submission` and
`Release Wrap Up` - are commented out in place rather than deleted, so the
cutover is easy to read and easy to undo. Delete those files, and drop the
`V2` prefix from these, once they have run a few cycles without incident.

`V2 Deploy Design Review` is kicked off manually by engineers as-needed. We use
that app to demonstrate implementation of a task or prototype that needs design
review, so designers can sign off before a task goes through PR review.

`V2 Deploy Alpha` builds the `Alpha` scheme. It currently points at test.wikipedia.org for donate, campaign, and feature configs.
It builds on every merge into `main`, and skips the build when the latest
commit is already tagged. Runs are serialized, and GitHub keeps only the newest
pending run, so a burst of merges collapses into one build.

#### Where Alpha builds: `ALPHA_BUILDER`

Alpha is our most frequent build, and it lands during peak developer hours, so
it can be moved off our macOS runners and onto Xcode Cloud. The `ALPHA_BUILDER`
repository variable (Settings > Secrets and variables > Actions > Variables) is
the one switch:

| `ALPHA_BUILDER` | What happens on a merge |
| --- | --- |
| unset or `github` | The `build-github` job archives on a macOS runner. The build number is the highest `alphas/` tag + 1, and the job pushes the tag. |
| `xcode-cloud` | The `build-xcode-cloud` job, on Linux, starts the Xcode Cloud **Alpha Build** workflow on `main` through the App Store Connect API (fastlane lane `xcode_cloud_alpha`, in [xcode_cloud.rb](../fastlane/xcode_cloud.rb)). It waits for the build, waits for TestFlight to process it, sets the What to Test notes and comments on Phabricator. Xcode Cloud sets the version and build number and pushes the `alphas/` tag itself (see below). No macOS runner is used. |

Both paths produce the same notes and Phabricator comments, from the
[alpha-release-notes](../.github/actions/alpha-release-notes/action.yml) and
[alpha-phabricator-comments](../.github/actions/alpha-phabricator-comments/action.yml)
actions. Either path builds the branch the run is dispatched from (`main` for
merges).

To try a path without changing the variable, dispatch `V2 Deploy Alpha`
manually and set **builder** to `github` or `xcode-cloud`. That applies to that
run only. Tick **lookup_only** (Xcode Cloud only) to check that the API key can
see the app, the Alpha Build workflow and the branch, and stop before starting
a build. Without it, a manual run is a real deploy: an Alpha in TestFlight, an
`alphas/` tag on the branch's commit and Phabricator comments. Xcode Cloud can
build a branch other than `main` only if Alpha Build's manual start condition
allows that branch.

For the variable to be the only switch, the Xcode Cloud **Alpha Build**
workflow's start condition must be **manual only**. Otherwise Xcode Cloud would
also build every merge by itself. Setup for `xcode-cloud`:

1. In Xcode Cloud, set Alpha Build's start condition to manual only. Check it still
   has its TestFlight Internal Testing post-action, and the
   `APPS_BOT_TOKEN` environment variable, which its tag script needs.
2. Set its next build number above the highest `alphas/` tag.
3. The App Store Connect API key in the `APP_STORE_*` secrets must have a role
   allowed to start Xcode Cloud builds. If the lane fails on `POST
   /v1/ciBuildRuns` with 403, that is why. To check the lookups without starting
   a build, run the lane with `XCODE_CLOUD_LOOKUP_ONLY=true`.
4. Set `ALPHA_BUILDER` to `xcode-cloud`.

To fall back, set `ALPHA_BUILDER` to `github`. Nothing in Xcode Cloud needs to
change. Before switching back to `xcode-cloud`, raise Alpha Build's next build
number above the highest `alphas/` tag again, because the GitHub path has used
numbers that Xcode Cloud does not know about.

Cancelling a run on the Xcode Cloud path doesn't stop the Xcode Cloud build. It
still uploads and tags; only the notes and Phabricator comments are lost.

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
second one generally means a wrap-up that never ran, OR there's an open PR to merge the previous RC commits back into main.

Release submission and wrap-up are covered by `V2 Submit App Store`, which
submits a build already in TestFlight rather than building one, and
`V2 Release Wrap Up`.

### Xcode Cloud fallback

Xcode Cloud has equivalent workflows named "Beta Build", "Alpha Build" and
"Experimental Build". These are the fallback for when GitHub Actions is
unavailable (except Alpha Build, which is the primary Alpha path when
`ALPHA_BUILDER` is `xcode-cloud`, above), and they set version and build numbers and push tags using the same
prefixes as the table above, via [ci_pre_xcodebuild.sh](../ci_scripts/ci_pre_xcodebuild.sh),
[ci_post_xcodebuild.sh](../ci_scripts/ci_post_xcodebuild.sh) and
[tag_script_xcodebuild.sh](../ci_scripts/tag_script_xcodebuild.sh).

Note that these scripts match on the Xcode Cloud workflow name exactly, so a
workflow has to be named "Beta Build", "Alpha Build" or "Experimental Build" to
get a build number and tag at all - anything else falls through and is left
alone.

**Before running a fallback build, make sure the workflow's next build number** in
its Xcode Cloud settings is above the highest existing tag for its prefix
(`exp/`, `alphas/` or `betas/`). Xcode Cloud keeps its own build number counter
and it is not derived from anything in this repo, so it does not know about
builds GitHub Actions has made since the last fallback run. Only one direction
synchronises on its own: Actions takes `max(tag) + 1`, so it picks up correctly
after an Xcode Cloud build without anyone doing anything, but nothing updates
Xcode Cloud in return. A stale value is not dangerous - App Store Connect
rejects a duplicate build number, so the upload fails rather than two builds
quietly sharing a number.

Also note the version is always the current UTC date, from
`date -u "+%Y.%m.%d"` in ci_pre_xcodebuild.sh. There is no way to pass one in.
That is fine for Alpha and Experimental, but it means a fallback Beta build
cannot target a release candidate's ship date - it will stamp today's instead,
creating a second version alongside the cycle's in App Store Connect.

## Relationship between wmf-apps-ci, GitHub Actions, and PR Status Checks

Our GitHub organization has a bot account called wmf-apps-ci which has been used for various reasons in the past. Currently for iOS, this bot account is used to make automated write commits to our repository. This happens in three instances:

1. When Xcode Cloud completes a Beta Build, Alpha Build or Experimental Build, [tag_script_xcodebuild.sh](../ci_scripts/tag_script_xcodebuild.sh) tags the commit with `betas/`, `alphas/` or `exp/{build number}` and pushes it to our remote repository using the wmf-apps-ci account. It does this with a fine-tuned personal access token set up in the wmf-apps-ci GitHub account settings, read from an `APPS_BOT_TOKEN` environment variable in the Xcode Cloud workflow settings - the same name as the GitHub Actions secret, holding the same token. The account name is a literal in the script, not a variable.

   **Xcode Cloud environment variables are per-workflow, not per-app.** Each workflow that tags needs its own copy. If it is missing the script fails with a clear message before attempting the push; an older revision read the account name from a `GITHUB_USERNAME` variable too, and an unset one there collapsed the URL to `https://:@github.com/...`, failing with `remote: No anonymous write access.` - which read like an expired token but meant an unset variable.

2. When a new commit is made to the twn branch, a GitHub action runs the localizations script, commits and pushes the changes to the remote repository using the wmf-apps-ci account. It does this with the same fine-tuned personal access token as the previous point. This personal access token is set as a GitHub Actions repository secret in iOS repository GitHub Settings.

3. The V2 deploy workflows push their git tags (`exp/`, `alphas/`, `betas/` and `releases/`) and create the `release-candidate/{date}` branch using the wmf-apps-ci account, with the same personal access token, read from the APPS_BOT_TOKEN repository secret.

### What happens when this token expires?

You should notice a few things:

- The V2 deploy workflows will build and upload to TestFlight successfully, then fail at their "Tag build" step. `V2 Deploy Beta` will also fail to push its release candidate branch.

- An Xcode Cloud Beta, Alpha or Experimental build will fail at its post-xcodebuild step. Note that nothing is distributed in that case: the tag script runs before the TestFlight post-action, so a failed tag fails the whole build and the archive never ships. This is the opposite of the GitHub Actions behaviour above, which uploads first and tags afterwards.

- When a Translatewiki PR is opened, you will no longer see the followup "Import translations from TranslateWiki" commit in the PR.

To fix this:
1. Log into GitHub as wmf-apps-ci. The account credentials are in the 1Password iOS Team Vault. Generate a new fine-tuned token with access to the Wikipedia iOS Repository. Save this token in the 1Password iOS Team Vault in case we need it elsewhere in the future.

2. Edit each Xcode Cloud workflow that pushes tags - Beta Build, Alpha Build and Experimental Build (this can be done in Xcode). Under Environment, update the `APPS_BOT_TOKEN` variable with this new token. It is per-workflow, so updating one workflow does not update the others.

3. Log back into your usual GitHub account. Go to the Wikipedia iOS repository Settings. Under Secrets and variables > Actions, update the APPS_BOT_TOKEN secret with this new token.

### Why don't we commit and push with the standard GitHub token / github-actions user account?

When the commit is made by github-actions in a PR, our unit tests refuse to run. This is apparently [by design](https://github.com/peter-evans/create-pull-request/issues/48#issuecomment-537478081), to avoid unending actions loops. We switched to making repository changes via the wmf-apps-ci when we noticed our Translatewiki PRs were not running unit tests. 
