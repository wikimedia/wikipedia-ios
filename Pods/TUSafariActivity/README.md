# TUSafariActivity

[![Version](https://img.shields.io/cocoapods/v/TUSafariActivity.svg?style=flat)](http://cocoadocs.org/docsets/TUSafariActivity)
[![License](https://img.shields.io/cocoapods/l/TUSafariActivity.svg?style=flat)](http://cocoadocs.org/docsets/TUSafariActivity)
[![Platform](https://img.shields.io/cocoapods/p/TUSafariActivity.svg?style=flat)](http://cocoadocs.org/docsets/TUSafariActivity)

`TUSafariActivity` is a `UIActivity` subclass that provides an "Open In Safari" action to a `UIActivityViewController`.

![TUSafariActivity screenshot](http://cl.ly/image/2i0n0H3f2g1X/TUSafariActivity.png "TUSafariActivity screenshot")

## Installation

### CocoaPods

TUSafariActivity is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod 'TUSafariActivity', '~> 1.0'

## Usage

*(See example Xcode project)*

Simply `alloc`/`init` an instance of `TUSafariActivity` and pass that object into the applicationActivities array when creating a `UIActivityViewController`.

### Objective-C

```objectivec
NSURL *URL = [NSURL URLWithString:@"http://google.com"];
TUSafariActivity *activity = [[TUSafariActivity alloc] init];
UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:@[activity]];
```

### Swift

```swift
let URL = NSURL(string: "http://google.com")!
let activity = TUSafariActivity()
let activityViewController = UIActivityViewController(activityItems: [URL], applicationActivities: [activity])
```

Note that you can include the activity in any `UIActivityViewController` and it will only be shown to the user if there is a URL in the activity items.