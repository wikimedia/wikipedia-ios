# Wikipedia iOS
The official Wikipedia iOS client.

[![Build Status](https://travis-ci.org/wikimedia/wikipedia-ios.svg)](https://travis-ci.org/wikimedia/wikipedia-ios) [![codecov.io](http://codecov.io/github/wikimedia/wikipedia-ios/coverage.svg?branch=master)](http://codecov.io/github/wikimedia/wikipedia-ios?branch=master) [![MIT license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/wikimedia/wikipedia-ios/master/LICENSE.txt)

* OS target: iOS 9.3 or higher
* Device target: iPhone, iPod, iPad
* License: MIT License
* Source repo: https://github.com/wikimedia/wikipedia-ios
* Code review:
  * GitHub: https://github.com/wikimedia/wikipedia-ios
  * Gerrit: https://gerrit.wikimedia.org/r/#/q/project:apps/ios/wikipedia,n,z
* Planning (bugs & features): https://phabricator.wikimedia.org/project/view/782/
* IRC chat: #wikimedia-mobile and #wikimedia-ios on irc.freenode.net
* Team page: https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS

## Development Team
The app is primarily being developed by the Wikimedia Foundation's [Mobile Apps team](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team). This README provides high-level guidelines for getting started with the project. If you have any questions, comments, or issues, the easiest way to talk to us is joining the #wikimedia-mobile channel on the freenode IRC server during Eastern and Pacific business hours. We'll also gladly accept any tickets filed against the [project in Phabricator](https://phabricator.wikimedia.org/project/view/782/).

## Building and Running
This project requires [Xcode 7](https://itunes.apple.com/us/app/xcode/id497799835) or higher to build.  The easiest way to get Xcode is from the [App Store](https://itunes.apple.com/us/app/xcode/id497799835?mt=12), but you can also download it from [developer.apple.com](https://developer.apple.com/) if you have an AppleID registered with an Apple developer account.

<!--No submodules being used, but if any are added, the following line should be uncommented-->
<!--Once you have Xcode (and build dependencies) installed, run `make prebuild` to ensure any dependencies required to build the project (mainly our submodules) are setup.-->
At this point, you should be able to open `Wikipedia.xcworkspace` and run the app on the iOS Simulator (using the **Wikipedia** scheme and target). If you encounter any issues, please don't hesitate to let us know via bug reports or messaging us on IRC (see above).

> Quick note: you might not see an app icon when first building the project after a clean checkout. See [Wikipedia App Icons](docs/app-icons.md) for information about generating the icons.

## Development
### Architecture
*TODO: We hope to have some high-level documentation on the application's architecture soon.*
### Best practices and coding style
You can find our current thinking on [iOS best practices](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/BestPractices) and [coding style](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/ObjectiveCStyleGuide) on our [team page](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS). The [WMFCodingStyle](./WikipediaUnitTests/Code/WMFCodingStyle.h) files are also canonical examples of our coding style, which are enforced using [clang-format](#clang-format).
### Dependencies
We use [Carthage](https://github.com/Carthage/Carthage) to manage third-party native dependencies and [npm](#npm) for web.  We've committed our Carthage dependencies and npm build artifacts to the repo so you don't need to rebuild them to build the project. You do need Carthage installed.
## Testing
The **Wikipedia** scheme is configured to execute the project's iOS unit tests, which can be run using the `Cmd+U` hotkey or the **Product->Test** menu bar action. You can also use the project's [Makefile](./Makefile) to run both in one action: `make verify`.

## Contributing
If you're interested in contributing to the project, you can find our current product, bug, and engineering backlogs on the [iOS App Phabricator project board](https://phabricator.wikimedia.org/project/view/782/). Once you pick a task, make sure you assign it to yourself to ensure nobody else duplicates your work.  The **#Easy** tag in Phabricator can also help you find tasks that are ideal for new contributors because they're small and/or well-defined.  We suggest you [filter the **#Easy** project to only show tasks in the Wikipedia iOS app projects](https://phabricator.wikimedia.org/project/board/169/query/OuulRzaqbmPh/).

We do all of our active development on the [develop](https://github.com/wikimedia/wikipedia-ios) branch. Your pull requests will automatically be targeted at that branch by Github. To make merging easier, be sure you create your branches based on the develop branch.

Once your contributions are ready for review, post a pull request on GitHub and Travis should verify your changes.  Once the build succeeds, one of the maintainers will stop to approve the changes for merging.

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

## Development Dependencies
We're doing what we can to optimize the build system to have as few dependencies as possible (i.e. cloning, building, and running should "Just Work"), but certain development and maintenance tasks will require the installation of specific tools. Many of these tools are installable using [Homebrew](http://brew.sh), which is our recommended package manager.

> **Homebrew and many other tools require the Xcode command line tools, which can be installed by running `xcode-select --install` on newer versions of OS X. They can also be installed via Xcode or downloaded from the [Apple Developer downloads page](https://developer.apple.com/downloads) on older versions of OS X.**

### Clang-Format
 
`brew install clang-format`

As mentioned in [best practices and coding style](#best-practices-and-coding-style), we use clang-format to lint the project's Objective-C code. Installation via Homebrew is straightforward: `brew install clang-format`. We use the [ClangFormat-Xcode plugin](https://github.com/travisjeffery/ClangFormat-Xcode) to format code on save. After installing the Xcode plugin, select "Format on Save", "Use System ClangFormat" and "File" (to use our .clang-format file) from the Edit > Clang Format menu.

### CocoaPods
 
`sudo gem install cocoapods` or, if you have rbenv or similar installed: `gem install cocoapods`.
 
[CocoaPods](https://cocoapods.org) is a Ruby gem that the project uses to download and integrate third-party iOS components (see `Podfile` for an up-to-date list). We have committed all of these dependencies to the repository itself, removing the need to install the gem or run before building the project. However, if you want to do anything related to CocoaPods (such as upgrading the version of CocoaPods or adding a dependency), please refer to the [Working With Cocoapods documentation](docs/working-with-cocoapods.md).

### NPM
 
`brew install npm`
 
[npm](https://www.npmjs.com/) is a package manager for [nodejs](https://nodejs.org). With it, we install various node modules as Javascript dependencies and development tools (see `www/package.json` for an up-to-date list). Similar to our native dependencies, we have committed certain files to the repository to remove node and npm as build dependencies in an effort to streamline typical application development. Please see [Wikipedia iOS Web Development](docs/web-dev.md) for more information about how to work with the web components in this project.

## Continuous Integration
Continuous integration is run on [Travis-CI](https://travis-ci.org) in response to pull request updates and merges to the **master** branch. See the `verify` lane in `fastlane/Fastfile` and our `.travis.yml` for details.

