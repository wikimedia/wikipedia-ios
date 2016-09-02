# VTAcknowledgementsViewController

_Ready to use “Acknowledgements”/“Licenses”/“Credits” view controller for [CocoaPods](http://cocoapods.org/). Now also available in Swift with [AcknowList](https://github.com/vtourraine/AcknowList)._

![Platform iOS](https://img.shields.io/cocoapods/p/VTAcknowledgementsViewController.svg)
[![Build Status](https://travis-ci.org/vtourraine/VTAcknowledgementsViewController.svg?branch=master)](https://travis-ci.org/vtourraine/VTAcknowledgementsViewController)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/VTAcknowledgementsViewController.svg)](https://cocoapods.org/pods/VTAcknowledgementsViewController)
[![CocoaPods documentation](https://img.shields.io/cocoapods/metrics/doc-percent/VTAcknowledgementsViewController.svg)](http://cocoadocs.org/docsets/VTAcknowledgementsViewController)
[![MIT license](http://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/vtourraine/VTAcknowledgementsViewController/raw/master/LICENSE)

![iPhone screenshot 1](http://vtourraine.github.io/VTAcknowledgementsViewController/screenshots/iPhone-300-01.png)
![iPhone screenshot 2](http://vtourraine.github.io/VTAcknowledgementsViewController/screenshots/iPhone-300-02.png)


## How to Install

This project is only useful if you use CocoaPods, so let’s assume that you’re indeed using CocoaPods.

1. Add `pod 'VTAcknowledgementsViewController'` in your `Podfile`.
2. Import the `Pods-acknowledgements.plist` file from the generated `Pods` folder to your main app project (so you need to run `pod install` at least once before using this pod; don’t copy the file itself, just add a reference).  
This file is now generated at `Pods/Target Support Files/Pods-{project}/Pods-{project}-acknowledgements.plist` (_cf._ [#28](https://github.com/vtourraine/VTAcknowledgementsViewController/issues/28), [#31](https://github.com/vtourraine/VTAcknowledgementsViewController/issues/31)).  
You can automate that step from your Podfile, [as pointed out by @billyto](https://github.com/vtourraine/VTAcknowledgementsViewController/issues/20).


## How to Use

The `VTAcknowledgementsViewController` instance is usually pushed to an existing `UINavigationController`.

``` objc
VTAcknowledgementsViewController *viewController = [VTAcknowledgementsViewController acknowledgementsViewController];
viewController.headerText = NSLocalizedString(@"We love open source software.", nil); // optional
[self.navigationController pushViewController:viewController animated:YES];
```


## Customization

If your `.plist` file is named something other than `Pods-acknowledgements.plist` (_e.g._ if you’re using fancy build targets), you can initialize the view controller with a custom file name or path.

``` objc
viewController = [[VTAcknowledgementsViewController alloc] initWithFileNamed:@"Pods-MyTarget-acknowledgements"];
```

``` objc
NSString *path = [[NSBundle mainBundle] pathForResource:@"Pods-MyTarget-acknowledgements" ofType:@"plist"];
viewController = [[VTAcknowledgementsViewController alloc] initWithPath:path];
```

The controller can also display a header and a footer. By default, they are loaded from the generated `plist` file, but you can also directly change the properties values.

``` objc
viewController.headerText = NSLocalizedString(@"We love open source software.", nil);
viewController.footerText = NSLocalizedString(@"Powered by CocoaPods.org", nil);
```

If you need to include licenses that are not part of the generated `plist`, or if you don’t want to use the generated `plist` at all, you can easily create new `VTAcknowledgement` instances, and add them to the acknowledgements array of the controller.

``` objc
VTAcknowledgement *customLicense = [[VTAcknowledgement alloc] init];
customLicense.title = NSLocalizedString(@"...", nil);
customLicense.text  = NSLocalizedString(@"...", nil);

viewController.acknowledgements = @[customLicense];
```

The controller title is a localized value for “acknowledgements” (12 languages supported!). You might want to use this localized value for the button presenting the controller, for instance.

``` objc
[button setTitle:[VTAcknowledgementsViewController localizedTitle]
        forState:UIControlStateNormal];
```

If you need to further customize the appearance or behavior of this pod, feel free to subclass its classes.


## Requirements

VTAcknowledgementsViewController requires iOS 5.0 and above, Xcode 7.0 and above, and uses ARC. If you need lower requirements, look for an [older version of this repository](https://github.com/vtourraine/VTAcknowledgementsViewController/releases).


## Credits

VTAcknowledgementsViewController was created by [Vincent Tourraine](http://www.vtourraine.net), and improved by a growing [list of contributors](https://github.com/vtourraine/VTAcknowledgementsViewController/contributors).


## License

VTAcknowledgementsViewController is available under the MIT license. See the [LICENSE.md](./LICENSE.md) file for more info.
