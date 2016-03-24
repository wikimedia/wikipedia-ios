# SAHistoryNavigationViewController

[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
)](https://developer.apple.com/iphone/index.action)
[![Language](http://img.shields.io/badge/language-swift-brightgreen.svg?style=flat
)](https://developer.apple.com/swift)
[![Version](https://img.shields.io/cocoapods/v/SAHistoryNavigationViewController.svg?style=flat)](http://cocoapods.org/pods/SAHistoryNavigationViewController)
[![License](https://img.shields.io/cocoapods/l/SAHistoryNavigationViewController.svg?style=flat)](http://cocoapods.org/pods/SAHistoryNavigationViewController)

**Support 3D Touch for iOS9!!**

![](./SampleImage/touch.gif)
![](./SampleImage/3dtouch.gif)
![](./SampleImage/sample.gif)

SAHistoryNavigationViewController realizes iOS task manager like UI in UINavigationContoller.

[ManiacDev.com](https://maniacdev.com/) referred.  
[https://maniacdev.com/2015/03/open-source-component-enhancing-the-back-button-with-view-history-navigation](https://maniacdev.com/2015/03/open-source-component-enhancing-the-back-button-with-view-history-navigation)

## Features

- [x] iOS task manager like UI
- [x] Launch Navigation History with Long tap action of Back Bar Button
- [x] Support Swift2.0
- [x] Support 3D Touch (If device is not supported 3D Touch, automatically replacing to long tap gesture.)

## Installation

#### CocoaPods

SAHistoryNavigationViewController is available through [CocoaPods](http://cocoapods.org). If you have cocoapods 0.38.0 or greater, you can install
it, simply add the following line to your Podfile:

    pod "SAHistoryNavigationViewController"

#### Manually

Add the [SAHistoryNavigationViewController](./SAHistoryNavigationViewController) directory to your project.

## Usage

If you install from cocoapods, You have to write `import SAHistoryNavigationViewController`.


#### Storyboard or Xib
![](./SampleImage/storyboard.png)

Set custom class of UINavigationController to SAHistoryNavigationViewController.
In addition, set module to SAHistoryNavigationViewController.

#### Code

You can use SAHistoryNavigationViewController as `self.navigationController` in ViewController, bacause implemented `extension UINavigationController` as below codes and override those methods in SAHistoryNavigationViewController.

```swift
extension UINavigationController {
  public weak var historyDelegate: SAHistoryNavigationViewControllerDelegate? {
      set {
          willSetHistoryDelegate(newValue)
      }
      get {
          return willGetHistoryDelegate()
      }
  }
  public func showHistory() {}
  public func setHistoryBackgroundColor(color: UIColor) {}
  public func contentView() -> UIView? { return nil }
  func willSetHistoryDelegate(delegate: SAHistoryNavigationViewControllerDelegate?) {}
  func willGetHistoryDelegate() -> SAHistoryNavigationViewControllerDelegate? { return nil }
}
```

And you have to initialize like this.


```swift
let ViewController = UIViewController()
let navigationController = SAHistoryNavigationViewController()
navigationController.setViewControllers([ViewController], animated: true)
presentViewController(navigationController, animated: true, completion: nil)
```

If you want to launch Navigation History without long tap action, use this code.

```swift
navigationController?.showHistory()
```

## Customize

If you want to customize background of Navigation History, you can use those methods.

```swift
navigationController?.contentView()
navigationController?.setHistoryBackgroundColor(color: UIColor)
```

This is delegate methods.

```swift
@objc public protocol SAHistoryNavigationViewControllerDelegate: NSObjectProtocol {
    optional func historyControllerDidShowHistory(controller: SAHistoryNavigationViewController, viewController: UIViewController)
}
```

## Requirements

- Xcode 7.0 or greater
- iOS8.0 or greater
- [MisterFusion](https://github.com/szk-atmosphere/MisterFusion)

## Author

Taiki Suzuki, s1180183@gmail.com

## License

SAHistoryNavigationViewController is available under the MIT license. See the LICENSE file for more info.
