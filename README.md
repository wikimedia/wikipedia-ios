# Wikipedia iOS
The official Wikipedia iOS app.

[![Wikipedia](https://circleci.com/gh/wikimedia/wikipedia-ios.svg?style=shield)](https://github.com/wikimedia/wikipedia-ios)
[![MIT license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/wikimedia/wikipedia-ios/main/LICENSE.txt)

* **License**: MIT License
* **Source repo**: https://github.com/wikimedia/wikipedia-ios
* **Planning (bugs & features)**: https://phabricator.wikimedia.org/project/view/782/
* **Team page**: https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS

**Note: The latest `main` branch is set up to build with Xcode 12.5.1.**

## Building and Running

In the directory, run `./scripts/setup`.  Note: going to `scripts` directory and running `setup` will not work due to relative paths.

Running `scripts/setup` will setup your computer to build and run the app. The script assumes you have Xcode installed already. It will install [homebrew](https://brew.sh) and [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html). It will also create a pre-commit hook that uses ClangFormat for linting.

After running `scripts/setup`, you should be able to open `Wikipedia.xcodeproj` and run the app on the iOS Simulator (using the **Wikipedia** scheme and target). If you encounter any issues, please don't hesitate to let us know via a [bug report](https://phabricator.wikimedia.org/maniphest/task/edit/form/1/?title=[BUG]&projects=wikipedia-ios-app-product-backlog,ios-app-bugs&description=%3D%3D%3D+How+many+times+were+you+able+to+reproduce+it?%0D%0A%0D%0A%3D%3D%3D+Steps+to+reproduce%0D%0A%23+%0D%0A%23+%0D%0A%23+%0D%0A%0D%0A%3D%3D%3D+Expected+results%0D%0A%0D%0A%3D%3D%3D+Actual+results%0D%0A%0D%0A%3D%3D%3D+Screenshots%0D%0A%0D%0A%3D%3D%3D+Environments+observed%0D%0A**App+version%3A+**+%0D%0A**OS+versions%3A**+%0D%0A**Device+model%3A**+%0D%0A**Device+language%3A**+%0D%0A%0D%0A%3D%3D%3D+Regression?+%0D%0A%0D%0A+Tag++task+with+%23Regression+%0A) or messaging us on IRC in #wikimedia-mobile on Freenode.

### Required Dependencies
If you'd rather install the development prerequisites yourself without our script:

* [**Xcode**](https://itunes.apple.com/us/app/xcode/id497799835) - The easiest way to get Xcode is from the [App Store](https://itunes.apple.com/us/app/xcode/id497799835?mt=12), but you can also download it from [developer.apple.com](https://developer.apple.com/) if you have an Apple ID registered with an Apple Developer account.
* [**ClangFormat**](https://clang.llvm.org/docs/ClangFormat.html) - We use this for linting.

## Contributing
Covered in the [contributing document](CONTRIBUTING.md).

## Development Guidelines
These are general guidelines rather than hard rules.

### Coding Guidelines
- **Objective-C** - [Apple's Coding Guidelines for Cocoa](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html)
- **Swift** - [swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

### Formatting
We use Xcode's default 4 space indentation and our `.clang-format` file with the pre-commit hook setup by `scripts/setup`. Currently, this does not enforce Swift formatting.

### Process and Code Review Norms
Covered in the [process document](docs/process.md).

### Logging
When reading logs, note that the log levels are shortened to emoji.
- 🗣️ Verbose
- 💬 Debug
- ℹ️ Info
- ⚠️ Warning
- 🚨 Error 

### Testing
The **Wikipedia** scheme is configured to execute the project's iOS unit tests, which can be run using the `Cmd+U` hotkey or the **Product → Test** menu bar action. In order for the tests to pass, the test device's language and region must be set to `en-US` in Settings → General → Language & Region. There is a [ticket filed](https://phabricator.wikimedia.org/T259859) to update the tests to pass regardless of language and region.

### Schemes and Targets
* **Wikipedia** - Points to production servers.
* **Staging** -  Pushed to TestFlight as a separate app bundle, and has the ability to toggle different staging environments within the `current` [property](https://github.com/wikimedia/wikipedia-ios/blob/de349525f652ca59c3437cd36fcb13846d737f1e/WMF%20Framework/Configuration.swift#L41) of `Configuration`:
    - An option of `appsLabsForPCS` will point to the [Apps team's staging environment](https://mobileapps.wmflabs.org) for page content.
    - An option of `deploymentLabsForEventLogging` will point to the  [Event Logging](https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging) staging environment. It is for testing analytics events that the app sends to Event Logging.
    - An option of `betaCluster` will point to the [MediaWiki beta cluster environment](https://www.mediawiki.org/wiki/Beta_Cluster) for most API calls. This is meant to be a more blanket environment setting, so if this value exists it will also force the beta cluster environment for page content on the article view as well as force the staging environment for event logging. This beta cluster environment is also where developers can test sandbox push notifications triggered across various wikis. This is selected by default.
* **Local Page Content Service and Announcements** - used in Debug mode only, has the ability to toggle different local environments within the `current` [property](https://github.com/wikimedia/wikipedia-ios/blob/de349525f652ca59c3437cd36fcb13846d737f1e/WMF%20Framework/Configuration.swift#L41) of `Configuration`:
    - An option of `localPCS` will point to a locally running [mobileapps](https://gerrit.wikimedia.org/r/q/project:mediawiki%252Fservices%252Fmobileapps) repository for page content. This is selected by default.
    - An option of `localAnnouncements` will point to a locally running [wikifeeds](https://gerrit.wikimedia.org/r/q/project:mediawiki%252Fservices%252Fwikifeeds) repository for the announcements endpoint. This is selected by default.
    -  All other endpoints will point to production.
* **RTL** - Launches the app in an RTL locale using the `-AppleLocale` argument.
* **Experimental** - For one off builds. Can point to whatever is needed for the given experiment. Pushed to TestFlight as a separate app bundle.
* **User Testing** - For user testing. Has an alternate configuration so that it can be delivered ad hoc. Pushed to TestFlight as a separate app bundle.
* **WMF** - Bundles up the app logic shared between the main app and the extensions (widgets, notifications).
* **Update Localizations** - Covered in the [localization document](docs/localization.md).
* **Update Languages** - For adding new Wikipedia languages or updating language configurations. Covered in the [languages document](docs/languages.md).
* **{{name}}Widget, {{name}}Notification, {{name}}Stickers** - Extensions for widgets, notifications, and stickers.

### Continuous Integration
Covered in the [CI document](docs/ci.md).

### Event Logging
Covered in the [event logging document](docs/event_logging.md).

### Web Development
The article view and several other components of the app rely on web components. Instructions for working on these components is covered in the [web development document](docs/web_dev.md).

### Contact Us
If you have any questions or comments, you can email us at mobile-ios-wikipedia[at]wikimedia dot org. We'll also gladly accept any [bug reports](https://phabricator.wikimedia.org/maniphest/task/edit/form/1/?title=[BUG]&projects=wikipedia-ios-app-product-backlog,ios-app-bugs&description=%3D%3D%3D+How+many+times+were+you+able+to+reproduce+it?%0D%0A%0D%0A%3D%3D%3D+Steps+to+reproduce%0D%0A%23+%0D%0A%23+%0D%0A%23+%0D%0A%0D%0A%3D%3D%3D+Expected+results%0D%0A%0D%0A%3D%3D%3D+Actual+results%0D%0A%0D%0A%3D%3D%3D+Screenshots%0D%0A%0D%0A%3D%3D%3D+Environments+observed%0D%0A**App+version%3A+**+%0D%0A**OS+versions%3A**+%0D%0A**Device+model%3A**+%0D%0A**Device+language%3A**+%0D%0A**App+language%3A**+%0D%0A%0D%0A%3D%3D%3D+Regression?+%0D%0A%0D%0A+Tag++task+with+%23Regression+%0A).
