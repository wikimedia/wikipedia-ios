# Wikipedia iOS
The official Wikipedia iOS client.

[![MIT license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/wikimedia/wikipedia-ios/develop/LICENSE.txt)

* License: MIT License
* Source repo: https://github.com/wikimedia/wikipedia-ios
* Planning (bugs & features): https://phabricator.wikimedia.org/project/view/782/
* IRC chat: #wikimedia-ios on irc.freenode.net
* Team page: https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS

## Development Team
The app is primarily being developed by the Wikimedia Foundation's [Mobile Apps team](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team). This README provides high-level guidelines for getting started with the project. If you have any questions, comments, or issues, the easiest way to talk to us is joining the #wikimedia-mobile channel on the Freenode IRC server during Eastern and Pacific business hours. We'll also gladly accept any tickets filed against the [project in Phabricator](https://phabricator.wikimedia.org/project/view/782/).

## Building and Running

### Minimum Requirements
* [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) - The easiest way to get Xcode is from the [App Store](https://itunes.apple.com/us/app/xcode/id497799835?mt=12), but you can also download it from [developer.apple.com](https://developer.apple.com/) if you have an AppleID registered with an Apple Developer account.

**Run `scripts/setup` before building & running in Xcode to install all of the required dependencies. This may take a while as it will also compile any code dependencies.**

`scripts/setup` will install:

* [Homebrew](https://brew.sh)
* [Carthage](https://github.com/Carthage/Carthage)
* [clang-format](https://clang.llvm.org/docs/ClangFormat.html)
* A pre-commit hook that runs clang-format on any changed files

At this point, you should be able to open `Wikipedia.xcodeproject` and run the app on the iOS Simulator (using the **Wikipedia** scheme and target). If you encounter any issues, please don't hesitate to let us know via a [bug report]( https://phabricator.wikimedia.org/maniphest/task/edit/form/1/?title=[BUG]&projects=wikipedia-ios-app-product-backlog,ios-app-bugs&description=%3D%3D%3D+How+many+times+were+you+able+to+reproduce+it?%0D%0A%0D%0A%3D%3D%3D+Steps+to+reproduce%0D%0A%23+%0D%0A%23+%0D%0A%23+%0D%0A%0D%0A%3D%3D%3D+Expected+results%0D%0A%0D%0A%3D%3D%3D+Actual+results%0D%0A%0D%0A%3D%3D%3D+Screenshots%0D%0A%0D%0A%3D%3D%3D+Environments+observed%0D%0A**App+version%3A+**+%0D%0A**OS+versions%3A**+%0D%0A**Device+model%3A**+%0D%0A**Device+language%3A**+%0D%0A%0D%0A%3D%3D%3D+Regression?+%0D%0A%0D%0A+Tag++task+with+%23Regression+%0A) or messaging us on IRC in #wikimedia-ios on Freenode.

## Development

### Guidelines
These are general guidelines rather than hard rules.

#### Objective-C
* [Apple's Coding Guidelines for Cocoa](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html)
#### Swift
* [swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

### Formatting
We use Xcode's default 4 space indentation and our `.clang-format` file with the pre-commit hook setup by `scripts/setup`. Currently, this does not enforce Swift formatting.

### Third-party Dependencies
We use [Carthage](https://github.com/Carthage/Carthage) to manage third-party native dependencies and [npm](#npm) for web.

## Testing
The **Wikipedia** scheme is configured to execute the project's iOS unit tests, which can be run using the `Cmd+U` hotkey or the **Product->Test** menu bar action.

## Contributing
Covered in the [contributing document](CONTRIBUTING.md).

### Gerrit
We also maintain a mirror of this repository on Gerrit (see above), syncing the code after every release. If you'd rather use Gerrit to send us a patch, you'll need to:

- [Create an SSH key](https://help.github.com/articles/generating-an-ssh-key/)
- [Create a Wikimedia developer account](https://wikitech.wikimedia.org/wiki/Special:UserLogin/signup)
- Clone the gerrit repo: `git clone ssh://<wikimedia-dev-username>@gerrit.wikimedia.org:29418/apps/ios/wikipedia.git`
- [Install git-review](https://www.mediawiki.org/wiki/Gerrit/git-review)
- Make some changes...
- Squash them into one commit (following our [commit subject and message guidelines](https://www.mediawiki.org/wiki/Gerrit/Commit_message_guidelines))
- Submit your commit review: `git review`
  - You should see a URL pointing your patch on [gerrit.wikimedia.org](https://gerrit.wikimedia.org)
- Add two or more of the [team members](#development-team) as reviewers for your patch

## Other Development Dependencies
Certain development and maintenance tasks will require the installation of specific tools. Many of these tools are installable using [Homebrew](http://brew.sh), which is our recommended package manager.

> **Homebrew and many other tools require the Xcode command line tools, which can be installed by running `xcode-select --install` on newer versions of OS X. They can also be installed via Xcode or downloaded from the [Apple Developer downloads page](https://developer.apple.com/downloads) on older versions of OS X.**

### Carthage
 
`brew install carthage`

We use [Carthage](https://github.com/Carthage/Carthage) as our dependency manager. It is required to build the project. After installing carthage, (or running `scripts/setup`) you should be able to build & run in Xcode. `scripts/carthage_bootstrap` is run as a build step by Xcode. Your first build will take a while as the dependencies are built. Subsequent builds will re-use the prebuilt dependencies.

#### Carthage Troubleshooting

Remove the `Carthage` and `Carthage Cache` folders inside of the repo directory. Also remove the  `org.carthage.CarthageKit` and `Carthage` folders from `~/Library/Caches/`. Then, run `make deps` or build in Xcode.

### Manually imported dependencies

HockeySDK is manually imported from their binary release. New binary releases of HockeySDK can be downloaded from https://www.hockeyapp.net/releases/ and copied over the existing version in the `Wikipedia/Frameworks` folder. We use the release in the `HockeySDKCrashOnly` folder.

### Clang-Format
 
`brew install clang-format`

As mentioned in [best practices and coding style](#best-practices-and-coding-style), we use clang-format to lint the project's Objective-C code. Installation via Homebrew is straightforward: `brew install clang-format`. We use a pre-commit hook to format code. The pre commit hook is `scripts/clang_format_diff` and is installed by `scripts/setup`.

### NPM
 
`brew install npm`
 
[npm](https://www.npmjs.com/) is a package manager for [nodejs](https://nodejs.org). With it, we install various node modules as Javascript dependencies and development tools (see `www/package.json` for an up-to-date list). Similar to our native dependencies, we have committed certain files to the repository to remove node and npm as build dependencies in an effort to streamline typical application development. Please see [Wikipedia iOS Web Development](docs/web-dev.md) for more information about how to work with the web components in this project.

### Fastlane

[fastlane](https://fastlane.tools) automates common development tasks - for example bumping version numbers, running tests on multiple configurations, or submitting to the App Store. You can list the available lanes (our project-specific scripts) using `bundle exec fastlane lanes`. You can list available actions (all actions available to be scripted via lanes) using `bundle exec fastlane actions`. The fastlane configuration and scripts are in the `fastlane` folder.

#### Production Builds
For production builds, should ensure you have the `DELIVER_USER` (your Apple ID) and `HOCKEY_PRODUCTION` (Wikimedia's HockeyApp API token) environment variables set.

## Continuous Integration
Tests are run on [Jenkins](https://jenkins.io) in response to pull requests. Volunteer contributor pull requests require an `ok to test` comment on the pull request from a project admin before tests are run. 
