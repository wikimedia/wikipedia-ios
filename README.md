Wikipedia for iOS
-----

# Meta
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

# Setup
Because of the nature of the project (read: lots of HTML), we have several layers of dependencies. Having said that, we have automated much of the setup so it's not too bad to set the project up and start contributing. 

Specifically, many tasks have been implemented in the `Makefile`. Run `make` or `make help` to see a list of available tasks (or targets).   For instance, simply run  `make build-sim` to see if your machine is setup and ready to go.

Read on to get started…

## Dependencies

### Before you start
#### Homebrew
Many of the dependencies below are installed easiest via [Homebrew](http://brew.sh). it is recommended that you install it before proceeding. If you run into issues installing dependencies with homebrew, run `brew doctor` to get hints on how to fix them.
#### Bundler
[Bundler](http://bundler.io/) is optional, but **required** for using the Make File and is recommended for installing CocoaPods, along with any other RubyGem dependencies declared in the project's `Gemfile`. 
#### Make File
Once Bundler is installed, you can run `make get-deps` to check for the dependencies below (it will also install any gems and pods for you automatically)

### Build Dependencies
These tools are needed for building and running the app.
- [Xcode 6 or higher](https://itunes.apple.com/us/app/xcode/id497799835) on Mac OS X, available on the App Store or [developer.apple.com](https://developer.apple.com/) after signing in with your Apple ID.  
- [Ruby](https://www.ruby-lang.org/en/): comes bundled with OS X (this project only requires the system version).
- [CocoaPods](cocoapods.org) is a Ruby gem that the project uses to download and integrate third-party iOS components.  
- [NodeJS](https://nodejs.org): The web assets which are bundled in the app are built using a Node toolchain, specifically [grunt](http://gruntjs.com) which is installed using [npm](npmjs.com).
- [ImageMagick](http://www.imagemagick.org) and [Ghostscript](http://www.ghostscript.com): We generate environment specific icons at build time using these tools. You can install them via homebrew by running `brew install imagemagick` and `brew install ghostscript`, respectively.

### Patch Submission Dependencies
These tools are required when you intend on submitting a patch.
- [uncrustify](http://uncrustify.sourceforge.net) for formatting source code to conform to our [Style Guide](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/ObjectiveCStyleGuide). You can install it using homebrew by running: `brew install uncrustify`.
> _[BBUncrustifyPlugin](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode) is an easy way to uncrustify files within the Xcode UI. You can install it from source or by first installing [Alcatraz](http://alcatraz.io)_

### CI Dependencies
These tools are required if you want to work on the build system.
- Xcode Command Line Tools: You can install via the Xcode UI or run `xcode-select --install` in Terminal. You can find instructions online for downloading the them via Xcode or the Apple developer portal.
- [Fastlane](https://github.com/KrauseFx/fastlane) is a Ruby gem that automates build tasks. We use Fastlane in conjunction with [Jenkins](https://jenkins-ci.org)  to support our [continuous integration workflow](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/CI).

### Advanced Tools
These tools are for managing multiple environments and dependencies. If you plan on modifying Pods or need this project's dependencies to coexist along side other projects, try these:
- [rbenv](https://github.com/sstephenson/rbenv) is nice for managing mulitple Ruby versions.
- [nodenv](https://github.com/OiNutter/nodenv) is recommended for managing multiple node versions.

## Building
Once all the dependencies are installed, you can run from build the following ways:
- **Xcode UI** - just open the `Wikipedia.workspace` file and click build.
- **xcodebuild** - you can build from the command line with the Apple provided tool.
- **Make file** - just type `make build-sim` in the Terminal and it will compile the project for the iOS simulator.
- **Fastlane** - just type `fastlane lane_name` to build the app for the specified lane.

### Problems?
If you are unable to build, please file a bug and/or contact us via IRC or email. See the top of this file for our contact information. Please include any console logs and/or Xcode screenshots along with a description of your environment.

## Running
Use Xcode to run the **WikipediaDebug** scheme and target for the destination of your choosing (i.e. simulator or device). Keep in mind that you'll need to provision iOS hardware with an active [developer account](https://developer.apple.com/devcenter/ios/index.action) in order to build and run the app on a device.

## Testing
Use the Xcode **Product -> Test** menu-bar action (or `Cmd + U` for hotkey fanatics) to run the **WikipediaUnitTests** target in any scheme.  Tests can also be executed from the command line by running `make test`.

# Filing Bugs
Please file bugs on [Phabricator](https://phabricator.wikimedia.org/project/profile/782/) and be sure to use the `Wikipedia-App-iOS-App ` tag.

# Submitting patches
Before submitting a patch be sure to use Uncrustify to format your code (See installation instructions above). 

> _To ease the process, you can install a pre-push hook by running the script  ```/scripts/setup_git_hooks.sh``` or by using the BBUncrustifyPlugin as mentioned above._

See [mediawiki.org's Gerrit page](https://www.mediawiki.org/wiki/Gerrit) for general information about contributing to Wikimedia project source code hosted in Gerrit -- use the project name "apps/ios/wikipedia" in place of "mediawiki/core" etc.

You can also follow or fork from our [GitHub mirror](https://github.com/wikimedia/apps-ios-wikipedia). Note that pull requests submitted through GitHub must be manually copied over to Gerrit for review and merge (though there is a bot we plan to enable to simplify this).

Please include unit tests with any new code where possible.

# Architecture
This generation of the Wikipedia app is built around native UI chrome (menus, toolbars, search UI, preferences, caching, etc) to improve startup time, responsiveness and "nativey" look-n-feel versus a previous HTML-based approach using PhoneGap/Apache Cordova.

The majority of app logic and UI will be in the native layer; we expect to use the WebView component as a relatively dumb content display & event trigger layer.

# Development team
The app is primarily being developed by the Wikimedia Foundation's [Mobile Apps team](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team), starting at the end of October 2013. We maintain iOS specific documentation [here](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS). The team operates on an "agile"-style process with 2-week sprints and daily stand-ups on at 10:15am US Pacific Time.

Volunteer contributions are welcome!

We can be reached during Eastern and Pacific office hours (and sometimes outside them) in IRC: #wikimedia-mobile on irc.freenode.net.

# Previous Source
This is a native rewrite of the original [Wikipedia reader application](https://www.mediawiki.org/wiki/Wikimedia_Apps/Wikipedia) for iOS.

