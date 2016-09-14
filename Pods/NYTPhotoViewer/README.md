# NYTPhotoViewer

[![Platform](http://cocoapod-badges.herokuapp.com/p/NYTPhotoViewer/badge.png)](http://cocoadocs.org/docsets/NYTPhotoViewer)
[![Version](http://cocoapod-badges.herokuapp.com/v/NYTPhotoViewer/badge.png)](http://cocoadocs.org/docsets/NYTPhotoViewer)

NYTPhotoViewer is a slideshow and image viewer that includes double-tap to zoom, captions, support for multiple images, interactive flick to dismiss, animated zooming presentation, and more.

![Demo GIF](Images/photo_viewer.gif)

## Usage

Usage is simple, with the option for more complicated customization when needed through a delegate relationship. In the most basic implementation, just initialize the view controller with an array of photo objects and present it as normal:

```objc
NYTPhotosViewController *photosViewController = [[NYTPhotosViewController alloc] initWithPhotos:photos];
[self presentViewController:photosViewController animated:YES completion:nil];
```

## Installation

### Carthage

NYTPhotoViewer may be installed via [Carthage](https://github.com/Carthage/Carthage). To install it, simply add the following line to your `Cartfile`:

```
github "NYTimes/NYTPhotoViewer"
```

Then, following the instructions for [integrating Carthage frameworks into your app](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos), link the `NYTPhotoViewer` and `FLAnimatedImage` frameworks into your project.

If you don't want support for animated GIFs, you may instead link against only the `NYTPhotoViewerCore` framework.

### Cocoapods

NYTPhotoViewer is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your `Podfile`:

```
pod 'NYTPhotoViewer', '~> 1.1.0'
```

## Requirements

This library requires a deployment target of iOS 8.0 or greater.

## Changelog

See [`CHANGELOG.md`](https://github.com/NYTimes/NYTPhotoViewer/blob/develop/CHANGELOG.md).

## Swift

NYTPhotoViewer is written in Objective-C but is intended to be fully interoperable with Swift. If you experience any interoperability difficulties, please open an issue or pull request and we will work to resolve it.

## Inspiration

NYTPhotoViewer draws feature inspiration from Facebook and Tweetbot’s image viewers. If this implementation isn’t to your liking, you may consider [JTSImageViewController](https://github.com/jaredsinclair/JTSImageViewController) or [IDMPhotoBrowser](https://github.com/ideaismobile/IDMPhotoBrowser).

## Implementation

NYTPhotoViewer has a straightforward implementation using standard UIKit components. The viewer is a `UIViewController` and uses `UIViewController` transitioning APIs for the animated and interactive transitions, a `UIPageViewController` for horizontal swiping between images, and `UIScrollView` for image zooming.

It is intended to be used without the need for subclassing, and as such it accepts model objects conforming to a `NYTPhoto` protocol and provides ample opportunity for customization via the `NYTPhotosViewControllerDelegate`. Since standard APIs are used, the client has full control over the transitions and customization of the `NYTPhotosViewController`.

## License

NYTPhotoViewer is available under the Apache 2.0 license. See [`LICENSE.md`](https://github.com/NYTimes/NYTPhotoViewer/blob/develop/LICENSE.md) for more information.

## Contributors

[A list of contributors is available through GitHub.](https://github.com/NYTimes/NYTPhotoViewer/graphs/contributors)
