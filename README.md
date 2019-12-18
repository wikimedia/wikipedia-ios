# Wikipedia iOS
The official Wikipedia iOS app.

[![MIT license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/wikimedia/wikipedia-ios/develop/LICENSE.txt)

* License: MIT License
* Source repo: https://github.com/wikimedia/wikipedia-ios
* Planning (bugs & features): https://phabricator.wikimedia.org/project/view/782/
* Team page: https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS

## Building and Running

In the directory, run `./scripts/setup`.  Note: going to `scripts` directory and running `setup` will not work due to relative paths.

Running `scripts/setup` will setup your computer to build and run the app. The script assumes you have Xcode installed already. It will install [homebrew](https://brew.sh), [Carthage](https://github.com/Carthage/Carthage), and [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html). It will also create a pre-commit hook that uses ClangFormat for linting.

After running `scripts/setup`, you should be able to open `Wikipedia.xcodeproj` and run the app on the iOS Simulator (using the **Wikipedia** scheme and target). If you encounter any issues, please don't hesitate to let us know via a [bug report](https://phabricator.wikimedia.org/maniphest/task/edit/form/1/?title=[BUG]&projects=wikipedia-ios-app-product-backlog,ios-app-bugs&description=%3D%3D%3D+How+many+times+were+you+able+to+reproduce+it?%0D%0A%0D%0A%3D%3D%3D+Steps+to+reproduce%0D%0A%23+%0D%0A%23+%0D%0A%23+%0D%0A%0D%0A%3D%3D%3D+Expected+results%0D%0A%0D%0A%3D%3D%3D+Actual+results%0D%0A%0D%0A%3D%3D%3D+Screenshots%0D%0A%0D%0A%3D%3D%3D+Environments+observed%0D%0A**App+version%3A+**+%0D%0A**OS+versions%3A**+%0D%0A**Device+model%3A**+%0D%0A**Device+language%3A**+%0D%0A%0D%0A%3D%3D%3D+Regression?+%0D%0A%0D%0A+Tag++task+with+%23Regression+%0A) or messaging us on IRC in #wikimedia-mobile on Freenode.

### Required dependencies
If you'd rather install the development prerequisites yourself without our script:

* [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) - The easiest way to get Xcode is from the [App Store](https://itunes.apple.com/us/app/xcode/id497799835?mt=12), but you can also download it from [developer.apple.com](https://developer.apple.com/) if you have an AppleID registered with an Apple Developer account.
* [Carthage](https://github.com/Carthage/Carthage) - We check in prebuilt dependencies to simplify the initial build and run experience but you'll still need Carthage installed to allow Xcode to properly copy the frameworks into the built app. After you add, remove, or upgrade a dependency, you should run `scripts/carthage_update` to update the built dependencies.
* [ClangFormat](https://clang.llvm.org/docs/ClangFormat.html) - We use this for linting

## Contributing
Covered in the [contributing document](CONTRIBUTING.md).

## Development Guidelines
These are general guidelines rather than hard rules.

### Objective-C
* [Apple's Coding Guidelines for Cocoa](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html)
### Swift
* [swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

### Formatting
We use Xcode's default 4 space indentation and our `.clang-format` file with the pre-commit hook setup by `scripts/setup`. Currently, this does not enforce Swift formatting.

### Process and code review norms
Covered in the [process document](docs/process.md).

### Testing
The **Wikipedia** scheme is configured to execute the project's iOS unit tests, which can be run using the `Cmd+U` hotkey or the **Product->Test** menu bar action. Screenshot tests will fail unless you are running on one of the configurations defined by `configurations_to_test_on_pull` in `fastlane/Fastfile`.

### Continuous integration
Covered in the [ci document](docs/ci.md).

### Event logging
Covered in the [event logging document](docs/event_logging.md).

### Web development
The article view and several other components of the app rely on web components. Instructions for working on these components is covered in the [web development document](docs/web_dev.md).

### Contact us
If you have any questions or comments, you can join the #wikimedia-mobile channel on the Freenode IRC server. We'll also gladly accept any [bug reports](https://phabricator.wikimedia.org/maniphest/task/edit/form/1/?title=[BUG]&projects=wikipedia-ios-app-product-backlog,ios-app-bugs&description=%3D%3D%3D+How+many+times+were+you+able+to+reproduce+it?%0D%0A%0D%0A%3D%3D%3D+Steps+to+reproduce%0D%0A%23+%0D%0A%23+%0D%0A%23+%0D%0A%0D%0A%3D%3D%3D+Expected+results%0D%0A%0D%0A%3D%3D%3D+Actual+results%0D%0A%0D%0A%3D%3D%3D+Screenshots%0D%0A%0D%0A%3D%3D%3D+Environments+observed%0D%0A**App+version%3A+**+%0D%0A**OS+versions%3A**+%0D%0A**Device+model%3A**+%0D%0A**Device+language%3A**+%0D%0A%0D%0A%3D%3D%3D+Regression?+%0D%0A%0D%0A+Tag++task+with+%23Regression+%0A).
