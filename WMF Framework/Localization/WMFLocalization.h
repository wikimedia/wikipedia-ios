#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Don't rename this function. It'll break the script that generates the strings. https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html
NSString *WMFLocalizedStringWithDefaultValue(NSString *key, NSString *_Nullable wikipediaLanguageCode, NSBundle *_Nullable bundle, NSString *value, NSString *comment);

@interface NSBundle (WMFLocalization)
@property (class, readonly, strong) NSBundle *wmf_localizationBundle;
@end

NS_ASSUME_NONNULL_END
