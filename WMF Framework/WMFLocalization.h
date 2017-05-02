#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

// Don't rename this function. It'll break the script that generates the strings. https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html
NSString *WMFLocalizedStringWithDefaultValue(NSString *key, NSURL *siteURL, NSBundle *bundle, NSString *value, NSString *comment);

NS_ASSUME_NONNULL_END
