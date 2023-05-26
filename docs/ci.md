# Wikipedia iOS Continuous Integration

Our continuous integration process involves a combination of both Xcode Cloud workflows and Github Actions.

## Localizations

We have a Github Action [workflow](../.github/workflows/localization.yml) that automatically runs our localizations script whenever a Translatewiki PR is opened against the `twn` branch. The file changes made from this script are then commited and pushed up to the PR branch. More details on this process can be found in the the [localization document](localization.md).

## PR Tests

Our PR unit tests are run in an Xcode Cloud workflow named "Run Tests". This kicks off any time a PR is opened or changed against any branch.


#### Localization Tests

In order to get our [localization tests](../WikipediaUnitTests/Code/TWNStringsTests.m) to run properly, some workarounds were needed to make the localization source code (files within `Wikipedia/iOS Native Localizations` and `Wikipedia/Localizations`) available in the Xcode Cloud environment.

1. We made references to source root directory dynamic, depending on if tests are running locally or within the Xcode Cloud context. This source root directory is referenced when pulling the resources referenced in `Wikipedia/iOS Native Localizations` or `Wikipedia/Localizations` for evaluations in these tests. We are using `SOURCE_ROOT_DIR` key in the unit tests Info.plist [file](../WikipediaUnitTests/Info.plist) which has value of $(SRCROOT) by default, to run locally. This key's value is then updated before tests are run in the Xcode Cloud environment, via [ci_pre_xcodebuild.sh](../ci_scripts/ci_pre_xcodebuild.sh) and our [copy_sourceroot.sh](../ci_scripts/copy_sourceroot.sh) script.
2. We added a relative symlink from `ci_scripts` to the localizations directories. First a `Wikipedia` directory was made in `ci_scripts`, then symlinks were added from that directory like this:

`ln -s ../../Wikipedia/"iOS Native Localizations" "iOS Native Localizations"`

Changes were then committed to git ([example](https://github.com/wikimedia/wikipedia-ios/pull/4507/commits/86d9f3150c2e5a021910eba0a3e21a96ad0a27e6)). 

## Nightly Production Build

Our CI process distributes a new production Wikipedia app to TestFlight for internal testers each night against the latest commit in our `main` branch. If there are no new commits since the last distribution, this workflow does not run. This two-step process allows us to distribute conditionally each night:

### GitHub Action

Every night, we run a Github [Action](../.github/workflows/tag_latest_beta.yml) titled "Tag Latest Beta". This script moves the git tag `latest_beta` to the latest commit in our `main` branch. If the `latest_beta` tag is already located at the last commit, it does nothing.

### Xcode Cloud

Xcode Cloud has a workflow titled "Nightly Build" that is set to trigger a build distribution whenever the `latest_beta` tag changes.

Once a build completes in this workflow, it pushes a git tag entitled `betas/{build number}` to the repository, so that we know which commit a nightly build is built against. It performs this task via [ci_post_xcodebuild.sh](../ci_scripts/ci_post_xcodebuild.sh) and our [tag_script_xcodebuild.sh](../ci_scripts/tag_script_xcodebuild.sh) script.

## Weekly Staging Build

Our CI process distributes a new staging Wikipedia app to TestFlight for internal testers once a week on Sundays. This staging app is pointed to various staging server environments, as well as has feature flags turned on for in-development feature testing.

This is done through Xcode Cloud on a schedule, via the workflow named "Weekly Staging Build". There is no additional GitHub Action component to make it conditional, like we do with the nightly build.

## Experimental Build

We also have an Xcode Cloud workflow that distributes a new experimental Wikipedia app for internal testers. This workflow must be kicked off manually by engineers as-needed. It can be run against any branch and defaults to the production server environment.

We use this app to demonstrate implementation of a task or prototype that needs design review. This allows designers to sign off before a task goes through the process of PR review. Once a PR is reviewed, approved and merged into `main`, the feature will make it into the production nightly build and the task moves to QA.
