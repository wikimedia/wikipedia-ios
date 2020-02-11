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
or alternatively using `brew cask install fastlane`

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
### ios beta_cluster_tests
```
fastlane ios beta_cluster_tests
```
Runs tests against the beta cluster to check for upstream changes.
### ios verify_pull_request
```
fastlane ios verify_pull_request
```
Runs tests on select platforms for verifying pull requests
### ios read_xcversion
```
fastlane ios read_xcversion
```

### ios verify
```
fastlane ios verify
```
Runs unit tests, generates JUnit reports.
### ios record_visual_tests
```
fastlane ios record_visual_tests
```
Records visual tests.
### ios bump_build
```
fastlane ios bump_build
```
Increment the build number
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
### ios push_beta
```
fastlane ios push_beta
```
updates version, builds, and pushes to TestFlight
### ios push_alpha
```
fastlane ios push_alpha
```
updates version, builds, and pushes alpha to TestFlight
### ios push_beta_cluster
```
fastlane ios push_beta_cluster
```
updates version, builds, and pushes beta cluster to TestFlight
### ios push_beta_app
```
fastlane ios push_beta_app
```
updates version, builds, and pushes beta cluster to TestFlight
### ios get_latest_tag_with_prefix
```
fastlane ios get_latest_tag_with_prefix
```

### ios get_latest_build_for_stage
```
fastlane ios get_latest_build_for_stage
```

### ios get_latest_alpha_or_beta_build_number
```
fastlane ios get_latest_alpha_or_beta_build_number
```

### ios push
```
fastlane ios push
```
updates version, builds, and pushes to TestFlight
### ios test_and_push_beta
```
fastlane ios test_and_push_beta
```
Runs tests, version, tag, and push to the beta branch
### ios upload_app_store_metadata
```
fastlane ios upload_app_store_metadata
```
Upload app store metadata
### ios submit_release
```
fastlane ios submit_release
```
Runs tests, version, tag, and push to the beta branch
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
