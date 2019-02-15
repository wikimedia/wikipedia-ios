# Wikipedia iOS Continuous Integration
This document describes the dependencies for working on continuous-integration-related aspects of the Wikipedia iOS project (automated building, testing, deployment, etc).

## Fastlane
`scripts/setup_fastlane` should install the required dependencies for using fastlane with this project

[fastlane](https://fastlane.tools) automates common development tasks - for example bumping version numbers, running tests on multiple configurations, or submitting to the App Store. You can list the available lanes (our project-specific scripts) using `bundle exec fastlane lanes`. You can list available actions (all actions available to be scripted via lanes) using `bundle exec fastlane actions`. The fastlane configuration and scripts are in the `fastlane` folder.


## Tests
Tests are run on [Jenkins](https://jenkins.io) on the `appsci` server in response to pull requests.

## Release builds
Are also handled by the `appsci` server. There is a Jenkins job for release that runs `fastlane push_beta`. This builds the app for release to the app store and uploads it to TestFlight. From there it is immediately released to internal beta and can be released to public beta and the app store after testing.