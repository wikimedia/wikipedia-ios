# Wikipedia iOS Continuous Integration
This document describes the dependencies for working on continuous-integration-related aspects of the Wikipedia iOS project (automated building, testing, deployment, etc).

## Prerequisites
- Xcode command line tools (see Development Dependencies section in the `README`)
- [Ruby](docs/working-with-ruby.md)

## Quick Start
Install the aforementioned dependencies (including running `bundle install` to download all required RubyGems), and you should be able to run any of the tasks defined in `fastlane/Fastfile`. Read on for more information about `fastlane` and the other tools we use as part of our CI pipeline.

## Fastlane
[Fastlane](https://github.com/KrauseFx/fastlane) is a Ruby gem that automates build tasks. We use it in conjunction with [Jenkins](https://jenkins-ci.org) to support our [continuous integration workflow](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/CI).

Lanes are documented in `fastlane/fastfile`.