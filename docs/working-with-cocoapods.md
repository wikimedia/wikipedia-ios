# Working With CocoaPods
This document is meant to brief developers who need to modify the Wikipedia iOS project's CocoaPods setup. In it, you'll find information on how to setup your machine to work with Ruby gems and CocoaPods, as well as information about how the project is configured with CocoaPods.

## Prerequisites
- Xcode command line tools
  - verify they're installed and up to date: `make xcode-cltools-check`
  - if that fails, you might need to update Xcode and/or install the command line tools via `make get-xcode-cltools`
- [Ruby](docs/working-with-ruby.md)

## Installing the CocoaPods RubyGem
The recommended method is to use Bundler to install all the gems required by the project by running `bundle install`. There's also a `Makefile` goal: `make bundle-install`. The reason this is the recommended method is to guarantee that all developers are using the same version of CocoaPods while gaining the same benefits of using Bundler mentioned in [Working With Ruby](docs/working-with-ruby.md).

## Updating To A New Verison Of CocoaPods
Simply modify the version specifier in the `Gemfile` and re-install it using Bundler as described in the [Installing the CocoaPods RubyGem](#installing-the-cocoapods-rubygem) section above.
