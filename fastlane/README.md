fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios checkout
```
fastlane ios checkout
```
Checks out the sha specified in the environment variables or the develop branch
### ios analyze
```
fastlane ios analyze
```
Runs linting (and eventually static analysis)
### ios verify_test_platforms
```
fastlane ios verify_test_platforms
```
Runs tests on the primary platforms and configurations
### ios verify_pull_request
```
fastlane ios verify_pull_request
```
Runs tests on select platforms for verifying pull requests
### ios read_xcversion
```
fastlane ios read_xcversion
```
Reads Xcode version from the .xcversion file and sets it using xcversion()
### ios verify
```
fastlane ios verify
```
Runs unit tests, generates reports.
### ios record_visual_tests
```
fastlane ios record_visual_tests
```
Records visual tests.
### ios set_build_number
```
fastlane ios set_build_number
```
Set the build number
### ios set_version_number
```
fastlane ios set_version_number
```
Set version number
### ios bump_patch
```
fastlane ios bump_patch
```
Increment the app version patch
### ios bump_minor
```
fastlane ios bump_minor
```
Increment the app version minor
### ios bump_major
```
fastlane ios bump_major
```
Increment the app version major
### ios tag
```
fastlane ios tag
```
Add a tag for the current build number and push to repo.
### ios tag_release
```
fastlane ios tag_release
```
Add a tag for the current version number push to repo.
### ios build
```
fastlane ios build
```
Build the app for distibution
### ios deploy
```
fastlane ios deploy
```
Pushes both the production and staging apps to TestFlight and tags the release. Only releases to internal testers.
### ios push_production
```
fastlane ios push_production
```
updates version, builds, and pushes the production build to TestFlight. Only releases to internal testers.
### ios push_staging
```
fastlane ios push_staging
```
Updates version, builds, and pushes the staging build to TestFlight. Only releases to internal testers.
### ios push_experimental
```
fastlane ios push_experimental
```
Updates version, builds, and pushes experimental build to TestFlight. Only releases to internal testers.
### ios get_latest_tag_with_prefix
```
fastlane ios get_latest_tag_with_prefix
```

### ios get_latest_build_number
```
fastlane ios get_latest_build_number
```

### ios push
```
fastlane ios push
```
updates version, builds, and pushes to TestFlight
### ios upload_app_store_metadata
```
fastlane ios upload_app_store_metadata
```
Upload app store metadata
### ios dsyms
```
fastlane ios dsyms
```
Download dSYMs from iTunes Connect
### ios dsyms_alpha
```
fastlane ios dsyms_alpha
```

### ios dsyms_beta
```
fastlane ios dsyms_beta
```

### ios dsyms_beta_app
```
fastlane ios dsyms_beta_app
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
