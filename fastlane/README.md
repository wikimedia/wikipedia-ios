fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios checkout

```sh
[bundle exec] fastlane ios checkout
```

Checks out the sha specified in the environment variables or the main branch

### ios analyze

```sh
[bundle exec] fastlane ios analyze
```

Runs linting (and eventually static analysis)

### ios verify_pull_request

```sh
[bundle exec] fastlane ios verify_pull_request
```

Runs tests on select platforms for verifying pull requests

### ios read_xcversion

```sh
[bundle exec] fastlane ios read_xcversion
```

Reads Xcode version from the .xcversion file and sets it using xcversion()

### ios verify

```sh
[bundle exec] fastlane ios verify
```

Runs unit tests, generates reports.

### ios record_visual_tests

```sh
[bundle exec] fastlane ios record_visual_tests
```

Records visual tests.

### ios set_build_number

```sh
[bundle exec] fastlane ios set_build_number
```

Set the build number

### ios set_version_number

```sh
[bundle exec] fastlane ios set_version_number
```

Set version number

### ios bump_patch

```sh
[bundle exec] fastlane ios bump_patch
```

Increment the app version patch

### ios bump_minor

```sh
[bundle exec] fastlane ios bump_minor
```

Increment the app version minor

### ios bump_major

```sh
[bundle exec] fastlane ios bump_major
```

Increment the app version major

### ios change_version

```sh
[bundle exec] fastlane ios change_version
```

Change version number and create PR with changes

### ios tag

```sh
[bundle exec] fastlane ios tag
```

Add a build tag for the current build number and push to repo. While this tags a build, tag_release sets a release tag.

### ios tag_release

```sh
[bundle exec] fastlane ios tag_release
```

Add a release tag for the latest beta and push to repo. For tagging non-releases, use `tag`.

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the app for distribution

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Pushes both the production and staging app to TestFlight and tags the release. Only releases to internal testers. (This is very similar to `push_production`, although this command also tags the build in git.)

### ios push_production

```sh
[bundle exec] fastlane ios push_production
```

Updates version, builds, and pushes the production build to TestFlight. Only releases to internal testers.

### ios push_staging

```sh
[bundle exec] fastlane ios push_staging
```

Updates version, builds, and pushes the staging build to TestFlight. Only releases to internal testers.

### ios push_experimental

```sh
[bundle exec] fastlane ios push_experimental
```

Updates version, builds, and pushes experimental build to TestFlight. Only releases to internal testers.

### ios get_latest_tag_with_prefix

```sh
[bundle exec] fastlane ios get_latest_tag_with_prefix
```



### ios get_latest_build_number

```sh
[bundle exec] fastlane ios get_latest_build_number
```



### ios get_recent_commits

```sh
[bundle exec] fastlane ios get_recent_commits
```



### ios push

```sh
[bundle exec] fastlane ios push
```

updates version, builds, and pushes to TestFlight

### ios upload_app_store_metadata

```sh
[bundle exec] fastlane ios upload_app_store_metadata
```

Upload app store metadata

### ios dsyms

```sh
[bundle exec] fastlane ios dsyms
```

Download dSYMs from iTunes Connect

### ios dsyms_alpha

```sh
[bundle exec] fastlane ios dsyms_alpha
```



### ios dsyms_beta

```sh
[bundle exec] fastlane ios dsyms_beta
```



### ios dsyms_beta_app

```sh
[bundle exec] fastlane ios dsyms_beta_app
```



----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
