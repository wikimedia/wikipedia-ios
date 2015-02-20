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

# Dependencies
##  [CocoaPods](cocoapods.org) 
To manage Objective-C dependencies.  See the `Podfile` for a comprehensive list.
## [npm](https://www.npmjs.com/) 
Manage web dependencies.  See `www/package.json` for a comprehensive list. 
## [Grunt](http://gruntjs.com)
Compile LESS files and other grunt work.
## [Uncrustify](http://uncrustify.sourceforge.net)
Code Beautifier

# Setup
## Prerequisites
Please make sure the following are installed on your system before trying to build the project:

- [Xcode 6 or higher](https://itunes.apple.com/us/app/xcode/id497799835) on Mac OS X, available on the App Store or [developer.apple.com](https://developer.apple.com/) after signing in with your Apple ID.
- Xcode Command Line Tools: On newer OS X versions, you can run `xcode-select --install` to install them.  If that doesn't work, you can find instructions online for downloading the them via Xcode or the Apple developer portal.
- Ruby: comes bundled with OS X (this project only requires the system version).

> _[rbenv](https://github.com/sstephenson/rbenv) is nice for managing mulitple Ruby versions._

- CocoaPods: Ruby gem for Objective-C dependency management.

> _[Bundler](http://bundler.io/) is recommended for installing Ruby gems without `sudo`._

- NodeJS: The web portion of the app is built using [npm](npmjs.com) to install node packages and [grunt](http://gruntjs.com) to manage tasks.

> _[nodenv](https://github.com/OiNutter/nodenv) is recommended for managing multiple node versions._

- [Uncrustify](http://uncrustify.sourceforge.net) for formatting source code to conform to our Style Guide. You can install with homebrew  ```brew install uncrustify```

> _[BBUncrustifyPlugin](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode) is an easy way to uncrustify files within the Xcode UI.

## Building
Once all the dependencies are installed, you'll have to do a couple of things before firing up Xcode and running the app:

- Setup CocoaPods
  - Install the **`cocoapods`** gem
  - Setup the CocoaPods specs repo by running `pod setup` (prepend `bundle exec` as needed)
  - Install our CocoaPods dependencies by going to the repository's root directory and running `pod install` (**not** `pod update`)
- Setup web components (if you're feeling lucky: `cd www && npm install && grunt`)
  - Go into the `www` directory
  - Run `npm install` to install our node dependencies
  - Run `grunt` to generate our web assets
- Open `Wikipedia.xcworkspace` in Xcode.  _Note the use of `.xcworkspace` extension—not `.xcodeproj`_
- Build the project!
- Profit! (Just kidding, we're non-profit)

If the build failed, we're _really_ sorry! We'll be more than happy to help you if you file a bug and/or bug us via IRC or email. See the top of this file for our contact information. Please include any console logs and/or Xcode screenshots along with a description of your environment.

## Running
Simply run the **Wikipedia** target for the destination of your choosing (i.e. simulator or device). Keep in mind that you'll need to provision any physical devices with an active [developer account](https://developer.apple.com/devcenter/ios/index.action) in order to build and run the app on them.

## Testing
The unit testing target is configured to build & test under the **Wikipedia** scheme. Use the Xcode **Product -> Test** menu-bar action (`Cmd + U` for hotkey fanatics) to run them. New unit tests (and their application-code dependencies) should be added to the **WikipediaUnitTests** target.

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
