//
//  WMFSettingsViewController.h
//  Wikipedia
//
//  Compatibility header for new SettingsViewController
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

// Forward declare the Swift SettingsViewController class
// so Objective-C code can reference it
@class SettingsViewController;

// Create a type alias for backward compatibility
typedef SettingsViewController WMFSettingsViewController;

NS_ASSUME_NONNULL_END
