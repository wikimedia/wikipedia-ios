# SVWebViewController

SVWebViewController is a simple inline browser for your iOS 7 app.

![SVWebViewController](http://cl.ly/SQVO/download/GitHub.png)

**SVWebViewController features:**

* iPhone and iPad distinct UIs
* full landscape orientation support
* back, forward, stop/refresh and share buttons
* Open in Safari and Chrome UIActivities
* navbar title set to the currently visible web page
* talks with `setNetworkActivityIndicatorVisible`

## Installation

### CocoaPods

I'm not a big fan of CocoaPods, so tend to not keep it updated. If you really want to use SVWebViewController with CocoaPods, I suggest you use `pod 'SVWebViewController', :head` to pull from the `master` branch directly. I'm usually careful about what I push there and is the version I use myself in all my projects.

### Manually

* Drag the `SVWebViewController/SVWebViewController` folder into your project.
* `#import "SVWebViewController.h"`

## Usage

(see sample Xcode project in `/Demo`)

Just like any UIViewController, SVWebViewController can be pushed into a UINavigationController stack:

```objective-c
SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:@"http://google.com"];
[self.navigationController pushViewController:webViewController animated:YES];
```

It can also be presented modally using `SVModalWebViewController`:

```objective-c
SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:@"http://google.com"];
[self presentModalViewController:webViewController animated:YES completion:NULL];
```

### SVWebViewControllerActivity

Starting in iOS 6 Apple uses `UIActivity` to let you show additional sharing methods in share sheets. `SVWebViewController` comes with "Open in Safari" and "Open in Chrome" activities. You can easily add your own activity by subclassing `SVWebViewControllerActivity` which takes care of a few things automatically for you. Have a look at the Safari and Chrome activities for implementation examples. Feel free to send it as a pull request once you're done!


## Credits

SVWebViewController is brought to you by [Sam Vermette](http://samvermette.com) and [contributors to the project](https://github.com/samvermette/SVWebViewController/contributors). If you have feature suggestions or bug reports, feel free to help out by sending pull requests or by [creating new issues](https://github.com/samvermette/SVWebViewController/issues/new). If you're using SVWebViewController in your project, attribution is always appreciated.