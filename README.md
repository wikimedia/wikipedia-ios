# Wikipedia iOS
The official Wikipedia iOS client.

* OS target: iOS 6.0 or higher
* Device target: iPhone, iPod, iPad
* License: MIT-style
* Source repo:
  * git clone https://git.wikimedia.org/git/apps/ios/wikipedia.git
  * Browse: https://git.wikimedia.org/summary/apps%2Fios%2Fwikipedia
  * Github mirror: https://github.com/wikimedia/apps-ios-wikipedia
* Code review: https://gerrit.wikimedia.org/r/#/q/project:apps/ios/wikipedia,n,z
* Bugs: https://phabricator.wikimedia.org/project/profile/782/
* IRC chat: #wikimedia-mobile on irc.freenode.net
* Team page: https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS

## Development Team
The app is primarily being developed by the Wikimedia Foundation's [Mobile Apps team](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team). This README provides high-level guidelines for getting started with the project. If you have any questions, comments, or issues, the easiest way to talk to us is joining the #wikimedia-mobile channel on the freenode IRC server during Eastern and Pacific business hours. We'll also gladly accept any tickets filed against the [project in Phabricator](https://phabricator.wikimedia.org/project/profile/782/).

## Building and Running
This project requires [Xcode 6](https://itunes.apple.com/us/app/xcode/id497799835) or higher. The easiest way to get it is from the [App Store](https://itunes.apple.com/us/app/xcode/id497799835?mt=12), but you can also download it from [developer.apple.com](https://developer.apple.com/) if you have an AppleID registered with an Apple developer account.

Once you have Xcode, you should be able to open `Wikipedia.xcworkspace` and run the app on the iOS Simulator (using the **Wikipedia** scheme and target). If you encounter any issues, please don't hesitate to let us know via a bug report or speaking to us on IRC.

## Development
### Architecture
*TODO: We hope to have some high-level documentation on the application's architecture soon.*
### Best practices and coding style
You can find our current thinking on [iOS best practices](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/BestPractices) and [coding style](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/ObjectiveCStyleGuide) on our [team page](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS). The [WMFCodingStyle](./WikipediaUnitTests/WMFCodingStyle.h) files are also canonical examples of our coding style, which are enforced using [uncrustify](#uncrustify).
### Dependencies
We use [CocoaPods](#cocoapods) to manage third-party native dependencies and [npm](#npm) for web. You shouldn't need to run either of these tools to build, run, or modify the application source, but if you do, refer to the sections below to get set up.

## Testing
The **Wikipedia** scheme is configured to execute the project's iOS unit tests, which can be run using the `Cmd+U` hotkey or the **Product->Test** menu bar action. In addition to unit testing, we enforce our coding style using [uncrustify](#uncrustify). You can also use the project's [Makefile](#makefile) to run both in one action: `make verify`.

## Contributing
If you're interested in contributing to the project, you can find our current product, bug, and engineering backlogs on the [iOS App Phabricator project board](https://phabricator.wikimedia.org/project/profile/782/). Once you pick a task, make sure you assign it to yourself to ensure nobody else duplicates your work.

Before submitting changes for review, please be sure to use [uncrustify](#uncrustify) to lint the code and [run the unit tests](#testing).  Now that the code is lint-free and the new tests (you did add tests, right?) it's time to submit the changes for review!

### Gerrit
Gerrit is our main vehicle for reviewing and merging code. You'll need to:

- [Create an SSH key](https://help.github.com/articles/generating-ssh-keys/)
- [Create a wikimedia developer account](https://wikitech.wikimedia.org/wiki/Special:UserLogin/signup)
- Clone the gerrit repo: `git clone ssh://<wikimedia-dev-username>@gerrit.wikimedia.org:29418/apps/ios/wikipedia.git`
- [Install git-review](https://www.mediawiki.org/wiki/Gerrit/git-review)
- Make some changes...
- Squash them into one commit (following our [commit subject and message guidelines](https://www.mediawiki.org/wiki/Gerrit/Commit_message_guidelines))
- Submit your commit review: `git review`
  - You should see a URL pointing your patch on [gerrit.wikimedia.org](https://gerrit.wikimedia.org)
- Add two or more of the [team members](#development-team) as reviewers for your patch

### GitHub
You can also follow or fork from our [GitHub mirror](https://github.com/wikimedia/apps-ios-wikipedia) (which you're probably looking at right now). Note that pull requests submitted through GitHub must be squashed and [submitted as a patch in Gerrit for review and merge](#gerrit). We're trying to think of ways to streamline this process.

## Development Dependencies
While typical application development is optimized to have as few dependencies as possible (i.e. cloning, building, and running should "Just Work"), certain development and maintenance tasks will require the installation of specific tools. Many of these tools are installable using [Homebrew](http://brew.sh), which our recommended package manager.

> **Homebrew and many other tools require the Xcode command line tools, which can be installed by running `xcode-select --install` on newer versions of OS X. They can also be installed via Xcode or downloaded from the [Apple Developer downloads page](https://developer.apple.com/downloads) on older versions of OS X.**

### Uncrustify
As mentioned in [best practices and coding style](#best-practices-and-coding-style), we use [uncrustify](http://uncrustify.sourceforge.net/) to lint the project's Objective-C code. Installation via Homebrew is straightforward: `brew install uncrustify`. We've also provided a pre-push git hook which automatically lints the code before pushing, which can be installed by running `./scripts/setup_git_hooks.sh`.

> [BBUncrustifyPlugin](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode) is an easy way to uncrustify files within the Xcode UI. You can install it from source or using [Alcatraz](http://alcatraz.io), the unofficial Xcode package/plugin manager.

### CocoaPods
[CocoaPods](cocoapods.org) is a Ruby gem that the project uses to download and integrate third-party iOS components (see `Podfile` for an up-to-date list). We have committed all of these dependnecies to the repository itself, removing the need to install the gem or run before building the project. However, if you want to do anything related to CocoaPods (such as upgrading the version of CocoaPods or adding a dependency), please refer to the [Working With Cocoapods documentation](docs/working-with-cocoapods.md).

### NPM
[npm](npmjs.com) is a package manager for [nodejs](nodejs.org). With it, we install various node modules as Javascript dependencies and development tools (see `www/package.json` for an up-to-date list). Similar to our native dependencies, we have committed certain files to the repository to remove node and npm as build dependencies in an effort to streamline typical application development. Please see [Wikipedia iOS Web Development](docs/web-dev.md) for more information about how to work with the web components in this project.

## Continuous Integration
This is still a work in progress. See [Wikipedia iOS Continuous Integration](docs/cont-integration.md) for more information.
