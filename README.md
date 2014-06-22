# Wikipedia-iOS

New (late 2013) native rewrite of the [Wikipedia reader application](https://www.mediawiki.org/wiki/Wikimedia_Apps/Wikipedia) for iOS.

This version has not yet been deployed to the App Store -- the source of the older app currently in the store is in the [WikipediaMobile project on GitHub](https://github.com/wikimedia/WikipediaMobile).

* OS target: iOS 6.0 or higher
* Device target: primary iPhone/iPod, secondary iPad
* License: MIT-style
* Source repo:
  * git clone https://git.wikimedia.org/git/apps/ios/wikipedia.git
  * Browse: https://git.wikimedia.org/summary/apps%2Fios%2Fwikipedia
  * Github mirror: https://github.com/wikimedia/apps-ios-wikipedia
* Code review: https://gerrit.wikimedia.org/r/#/q/project:apps/ios/wikipedia,n,z
* Bugs: https://bugzilla.wikimedia.org/
* IRC chat: #wikimedia-mobile on irc.freenode.net


# Building

Requires [Xcode 5 or higher](https://itunes.apple.com/us/app/xcode/id497799835) on Mac OS X, with the bundled iOS 7 SDK. You may need to get Xcode 5.1 beta with iOS 7.1 beta to support the latest storyboard - it's available at [developer.apple.com](https://developer.apple.com/) after signing in with your Apple ID.

Standard Xcode project stuff: check out the repo, open Wikipedia.xcodeproj in Xcode 5, pick a device or simulator target and hit ⌘R.

Note that due to Apple's restrictions on iOS app installation, to run a custom build on a standard iOS device you must pay for a [developer account with Apple](https://developer.apple.com/devcenter/ios/index.action) and register the device with your account.

You'll also need to install [nodejs](http://nodejs.org/) and npm.

# Running tests

In Xcode, hit ⌘U to run tests. Note that tests must run on iOS 7 simulator or device -- they do not run successfully on iOS 6.x.


# Filing Bugs

Please file bugs at [bugzilla.wikimedia.org](https://bugzilla.wikimedia.org/); use the "Wikipedia App" component.

Note that existing bug reports for other versions of the app may be mixed in there; this requires some cleanup.


# Submitting patches

See [mediawiki.org's Gerrit page](https://www.mediawiki.org/wiki/Gerrit) for general information about contributing to Wikimedia project source code hosted in Gerrit -- use the project name "apps/ios/wikipedia" in place of "mediawiki/core" etc.

You can also follow or fork from our [GitHub mirror](https://github.com/wikimedia/apps-ios-wikipedia). Note that pull requests submitted through GitHub must be manually copied over to Gerrit for review and merge (though there is a bot we plan to enable to simplify this).

Please include unit tests with any new code where possible.


# Architecture

This generation of the Wikipedia reader app is built around native UI chrome (menus, toolbars, search UI, preferences, caching, etc) to improve startup time, responsiveness and "nativey" look-n-feel versus a previous HTML-based approach using PhoneGap/Apache Cordova.

The majority of app logic and UI will be in the native layer; we expect to use the WebView component as a relatively dumb content display & event trigger layer.

Components of the app will be relatively self-contained, communicating via NSNotificationCenter as a messaging bus to avoid over-close coupling of parts and to make test-driven development more feasible.


# Design

A major complaint about the currently deployed Wikipedia app is its non-iOS-y UI appearance and behavior.

We'll be working with the Wikimedia Foundation's Design team on UI design, with an eye to coordinating the look & branding with mobile web and Android while keeping a nice native iOS 7 feel.


# Development team

The app is primarily being developed by the Wikimedia Foundation's [Mobile Apps team](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team), starting at the end of October 2013. The team operates on an "agile"-style process with 2-week sprints, and checkin scrums on Monday/Wednesday/Friday at 10:15am US Pacific Time.

In addition to a general bug pool in Bugzilla, we'll be tracking ongoing work on the [backlog board](https://trello.com/b/h0B6QYBo/wikipedia-app-backlog) and active sprint boards on Trello.

Volunteer contributions are welcome!

We can be reached during California office hours (and sometimes outside them) in IRC: #wikimedia-mobile on irc.freenode.net.

