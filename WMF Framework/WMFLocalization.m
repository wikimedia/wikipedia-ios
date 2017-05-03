#import "WMFLocalization.h"

static NSString *const WMFLocalizationBundleIdentifier = @"org.wikimedia.WMF";

NSString *WMFLocalizedStringWithDefaultValue(NSString *key, NSURL * _Nullable url, NSBundle *bundle, NSString *value, NSString *comment) {
    NSString *language = url.wmf_language;
    if (language == nil) {
       return NSLocalizedStringWithDefaultValue(key, nil, bundle, value, comment);
    }
    NSString *path = [[NSBundle bundleWithIdentifier:WMFLocalizationBundleIdentifier] pathForResource:language ofType:@"lproj"];
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
