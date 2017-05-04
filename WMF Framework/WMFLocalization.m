#import "WMFLocalization.h"

static NSString *const WMFLocalizationBundleIdentifier = @"org.wikimedia.WMF";

@interface NSBundle (WMFLocalization)
@property (class, readonly, strong) NSBundle *wmf_localizationBundle;
@end

@implementation NSBundle (WMFLocalization)
+ (NSBundle *)wmf_localizationBundle {
    return [NSBundle bundleWithIdentifier:WMFLocalizationBundleIdentifier];
}
@end

NSString *WMFLocalizedStringWithDefaultValue(NSString *key, NSURL * _Nullable url, NSBundle * _Nullable bundle, NSString *value, NSString *comment) {
    if (bundle == nil) {
        bundle = NSBundle.wmf_localizationBundle;
    }
    NSString *language = url.wmf_language;
    if (language == nil) {
       return NSLocalizedStringWithDefaultValue(key, nil, bundle, value, comment);
    }
    NSString *path = [bundle pathForResource:language ofType:@"lproj"];
    NSBundle *languageBundle = [NSBundle bundleWithPath:path];
    NSString *translation = nil;
    if (languageBundle) {
        translation = [languageBundle localizedStringForKey:key value:@"" table:nil];
    }
    if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
        return NSLocalizedStringWithDefaultValue(key, nil, bundle, value, comment);
    }
    return translation ? translation : @"";
}
