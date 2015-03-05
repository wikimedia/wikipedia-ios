# Wikipedia-iOS
Native rewrite of the [Wikipedia reader application](https://www.mediawiki.org/wiki/Wikimedia_Apps/Wikipedia) for iOS.

* OS target: iOS 6.0 or higher
* Device target: iPhone, iPod, iPad
* License: MIT-style
* Source repo:
  * git clone https://git.wikimedia.org/git/apps/ios/wikipedia.git
  * Browse: https://git.wikimedia.org/summary/apps%2Fios%2Fwikipedia
  * Github mirror: https://github.com/wikimedia/apps-ios-wikipedia
* Code review: https://gerrit.wikimedia.org/r/#/q/project:apps/ios/wikipedia,n,z
* Bugs: https://bugzilla.wikimedia.org/enter_bug.cgi?product=Wikipedia%20App
* IRC chat: #wikimedia-mobile on irc.freenode.net

# Setup
Many tasks associated with project dependencies or building are implemented in the `Makefile`. Run `make` or `make help` to see a list of available tasks (or targets). The TL;DR; one liner to sanity check the project's build status is: `make build-sim`.  Read on for more information about our dependencies and setting up the project.

## Dependencies
Run `make get-deps` to check for and/or install the following dependencies:

- [Xcode 6 or higher](https://itunes.apple.com/us/app/xcode/id497799835) on Mac OS X, available on the App Store or [developer.apple.com](https://developer.apple.com/) after signing in with your Apple ID.
- Xcode Command Line Tools: On newer OS X versions, you can run `xcode-select --install` to install them.  If that doesn't work, you can find instructions online for downloading the them via Xcode or the Apple developer portal.
- Ruby: comes bundled with OS X (this project only requires the system version).

> _[rbenv](https://github.com/sstephenson/rbenv) is nice for managing mulitple Ruby versions._

- [CocoaPods](cocoapods.org) is a Ruby gem that the project uses to download and integrate third-party iOS components.

> _[Bundler](http://bundler.io/) is recommended for installing CocoaPods, along with any other RubyGem dependencies declared in the project's `Gemfile`._

- NodeJS: The web assets which are bundled in the app are built using a Node toolchain, specifically [grunt](http://gruntjs.com) which is installed using [npm](npmjs.com).

> _[nodenv](https://github.com/OiNutter/nodenv) is recommended for managing multiple node versions._

- [uncrustify](http://uncrustify.sourceforge.net) for formatting source code to conform to our [Style Guide](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/ObjectiveCStyleGuide). You can install it using homebrew by running: `brew install uncrustify`.

> _[BBUncrustifyPlugin](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode) is an easy way to uncrustify files within the Xcode UI._

## Building
Once all the dependencies are installed (via `make get-deps`), you should be able to run `make build-sim`, which compiles the project for the iOS simulator. If this step doesn't succeed, please file a bug and/or bug us via IRC or email. See the top of this file for our contact information. Please include any console logs and/or Xcode screenshots along with a description of your environment.

## Running
Use Xcode to run the **Wikipedia** scheme and target for the destination of your choosing (i.e. simulator or device). Keep in mind that you'll need to provision iOS hardware with an active [developer account](https://developer.apple.com/devcenter/ios/index.action) in order to build and run the app on it.

## Testing
Use the Xcode **Product -> Test** menu-bar action (or `Cmd + U` for hotkey fanatics) to run the **WikipediaUnitTests** target in the **Wikipedia** scheme.  Tests can also be executed from the command line by running `make test`.

# Filing Bugs
Please file bugs at [bugzilla.wikimedia.org](https://bugzilla.wikimedia.org/enter_bug.cgi?product=Wikipedia%20App); use the "iOS App" component.

# Submitting patches
Before submitting a patch be sure to use Uncrustify to format your code (See installation instructions above). To make it easy, you can install a pre commit hook by running the script  ```/scripts/setup_git_hooks.sh``` or by using the BBUncrustifyPlugin as mentioned above.

See [mediawiki.org's Gerrit page](https://www.mediawiki.org/wiki/Gerrit) for general information about contributing to Wikimedia project source code hosted in Gerrit -- use the project name "apps/ios/wikipedia" in place of "mediawiki/core" etc.

You can also follow or fork from our [GitHub mirror](https://github.com/wikimedia/apps-ios-wikipedia). Note that pull requests submitted through GitHub must be manually copied over to Gerrit for review and merge (though there is a bot we plan to enable to simplify this).

Please include unit tests with any new code where possible.

# Architecture
This generation of the Wikipedia reader app is built around native UI chrome (menus, toolbars, search UI, preferences, caching, etc) to improve startup time, responsiveness and "nativey" look-n-feel versus a previous HTML-based approach using PhoneGap/Apache Cordova.

The majority of app logic and UI will be in the native layer; we expect to use the WebView component as a relatively dumb content display & event trigger layer.

Components of the app will be relatively self-contained, communicating via NSNotificationCenter as a messaging bus to avoid over-close coupling of parts and to make test-driven development more feasible.

# Development team
The app is primarily being developed by the Wikimedia Foundation's [Mobile Apps team](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team), starting at the end of October 2013. The team operates on an "agile"-style process with 2-week sprints, and checkin scrums on Monday/Wednesday/Friday at 10:15am US Pacific Time.

In addition to a general bug pool in Bugzilla, we'll be tracking ongoing work on the [backlog board](https://trello.com/b/h0B6QYBo/mobile-app-backlog) and active sprint boards on Trello.

Volunteer contributions are welcome!

We can be reached during California office hours (and sometimes outside them) in IRC: #wikimedia-mobile on irc.freenode.net.
