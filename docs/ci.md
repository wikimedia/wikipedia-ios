# Wikipedia iOS Continuous Integration
This document describes the dependencies for working on continuous-integration-related aspects of the Wikipedia iOS project (automated building, testing, deployment, etc).

## Fastlane

[fastlane](https://fastlane.tools) automates common development tasks - for example bumping version numbers, running tests on multiple configurations, or submitting to the App Store. You can list the available lanes (our project-specific scripts) using `bundle exec fastlane lanes`. You can list available actions (all actions available to be scripted via lanes) using `bundle exec fastlane actions`. The fastlane configuration and scripts are in the `fastlane` folder.

Fastlane isn't necessary for normal development, but will be necessary if you need to automate tasks locally or you'll be updating the lanes run on our CI server.

Similar to the [project's node setup for web dev](web_dev.md), we recommend using a Ruby version manager to install node and manage multiple versions of Ruby on the same machine.

These are the recommended steps for setting up Fastlane:

#### Install [homebrew](https://brew.sh)
[homebrew](https://brew.sh) should have been installed by `scripts/setup`, but if you didn't run that script or would like to manually install it:
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

#### Install [rbenv](https://github.com/rbenv/rbenv)
rbenv installs Ruby inside of your home folder so you don't have to modify the macOS ruby installation using root privileges. You can also manage multiple ruby versions on the same machine if you have other projects that depend on a different Ruby version. After [homebrew](https://brew.sh) is installed, install [rbenv](https://github.com/rbenv/rbenv) by running:
```
brew install rbenv
```

#### Update your ~/.bash_profile
Once the install command completes, add `eval "$(rbenv init -)"` to your `~/.bash_profile` (create this file if it doesn't exist)

#### Restart Terminal
After terminal restarts, verify that [rbenv](https://github.com/rbenv/rbenv) is working properly by typing `which ruby` and verifying it shows a path inside your home folder.

#### Install the required ruby version
First `cd` to the directory where you have this repository:
```
cd /path/to/your/wikipedia-ios
```

Then, install the ruby version specified by our project by running:
```
rbenv install -s
```

Verify it was installed by running `ruby -v` and matching it to the version number specified in the `.ruby-version` file in this repository.

#### Install bundler
Next, install bundler by running:
```
gem install bundler
```

#### Install gems
First `cd` to the directory where you have this repository if you aren't there already:
```
cd /path/to/your/wikipedia-ios
```
Next, install the Ruby dependencies (gems) specified by the `Gemfile` (including Fastlane) by running:
```
bundle install
```

Verify fastlane was installed by running `bundle exec fastlane lanes` and verifying it shows a list of lanes defined by this project.

## Xcode version
You can set the Xcode version used by fastlane by editing the `.xcversion` file in the root directory of the repo. This is helpful when a branch uses a new Xcode beta and you'd like to be able to utilize different Xcode versions for building each branch. 

Additionally, the Xcode version used by Circle CI is set in `.circleci/config.yml`

## Tests
Tests are run on [Circle CI](https://app.circleci.com/pipelines/github/wikimedia/wikipedia-ios) in response to pull requests. You can run the same tests that are run on a pr locally by running `bundle exec fastlane verify_pull_request`.

## Jenkins server and releasing
Are handled by the `wmf2249` server. After logging onto the WMF VPN, open a web browser and navigate to the [Jenkins instance](https://wmf2249:8043/). 

There are several Jenkins jobs:
- **Deploy** - This builds the app from a given branch (defaults to `main`) and uploads it to App Store Connect (essentially running `bundle exec fastlane deploy`). It is immediately released to internal beta, and can be released to an external beta or wide release via App Store Connect. This job automatically runs nightly, if there are new commits to `main`. 
- **Experimental** - This the app from a given branch (defaults to `main`) and uploads it as the Experimental TestFlight app (aka "Black icon") to App Store Connect. It is immediately released to internal beta, and can be released to an external beta via App Store Connect.
- **Post-release - Git tag as release** - Should be manually run after each release to the app store. Uploads a git tag for a release. (`bundle exec fastlane tag_release build_tag:[tag]`)
- **Post-release - Increase app version** - Should be manually run after each release to the app store. Updates the release number in Xcode.

## Build server maintenance
If you need to do more intensive build server work - like updating Xcode on the build server - when on the VPN, use the `Screen Sharing` macOS app to log into `wmf2249`.

To rotate App Store Connect credentials, log into the build server via the `Jenkins` account and update the files in the account's home directory. 

To rotate GitHub credentials, update them via the Jenkins web interface.
