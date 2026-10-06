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

`V2 Deploy Design Review` is kicked off manually by engineers as-needed. We use
that app to demonstrate implementation of a task or prototype that needs design
review, so designers can sign off before a task goes through PR review.

`V2 Deploy Alpha` builds the `Alpha` scheme, which points at various staging
server environments and has feature flags turned on for in-development testing.
It is meant to run nightly against `main`, and skips the build when the latest
commit is already tagged.

`V2 Deploy Beta` builds the production app from a `release-candidate/YYYY.MM.DD`
branch, which it reuses if one exists or cuts from `main` if not. The version
name comes from that branch's date.

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

Our GitHub organization has a bot account called wmf-apps-ci which has been used for various reasons in the past. Currently for iOS, this bot account is used to make automated write commits to our repository. This happens in three instances:

1. When Xcode Cloud completes a Beta Build, it tags the commit with `betas/{build number}` and pushes it to our remote repository using the wmf-apps-ci account. It does this with a fine-tuned personal access token set up in the wmf-apps-ci GitHub account settings. This personal access token is then set as an environment variable in Xcode Cloud Settings.

2. When a Translatewiki PR is opened, a GitHub action runs the localizations script, commits and pushes the changes to the remote repository using the wmf-apps-ci account. It does this with the same fine-tuned personal access token as the previous point. This personal access token is set as a GitHub Actions repository secret in iOS repository GitHub Settings.

3. We have a manually-triggered GitHub action that posts a PR to increment the app version. This commit is made with the wmf-apps-ci account. It does this with the same fine-tuned personal access token as the previous point. This personal access token is set as a GitHub Actions repository secret in iOS repository GitHub Settings.

### What happens when this token expires?

You should notice a few things:

- When a Beta Build is made, you will no longer see new `betas/{build number}` tag numbers added to the `main` branch.

- When a Translatewiki PR is opened, you will no longer see the followup "Import translations from TranslateWiki" commit in the PR.

- Running the "Update App Version" GitHub action manually will probably fail.

To fix this:
1. Log into GitHub as wmf-apps-ci. The account credentials are in the 1Password iOS Team Vault. Generate a new fine-tuned token with access to the Wikipedia iOS Repository. Save this token in the 1Password iOS Team Vault in case we need it elsewhere in the future.

2. Edit the Xcode Cloud Beta Build workflow (this can be done in Xcode). Under environment, update the `GITHUB_PAT` variable with this new token.

3. Log back into your usual GitHub account. Go to the Wikipedia iOS repository Settings. Under Secrets and variables > Actions, update the APPS_BOT_TOKEN secret with this new token.

### Why don't we commit and push with the standard GitHub token / github-actions user account?

When the commit is made by github-actions in a PR, our unit tests refuse to run. This is apparently [by design](https://github.com/peter-evans/create-pull-request/issues/48#issuecomment-537478081), to avoid unending actions loops. We switched to making repository changes via the wmf-apps-ci when we noticed our Translatewiki and Update App Version PRs were not running unit tests. 
