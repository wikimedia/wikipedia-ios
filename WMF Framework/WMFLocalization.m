#import "WMFLocalization.h"

static NSString *const WMFLocalizationBundleIdentifier = @"org.wikimedia.WMF";

NSString *WMFLocalizedStringWithDefaultValue(NSString *key, NSURL *url, NSBundle *bundle, NSString *value, NSString *comment) {
    NSString *language = url.wmf_language;
    if (language == nil) {
        language = @"en";
    }
    NSString *path = [[NSBundle bundleWithIdentifier:WMFLocalizationBundleIdentifier] pathForResource:language ofType:@"lproj"];
    NSBundle *languageBundle = [NSBundle bundleWithPath:path];
    NSString *translation = nil;
    if (languageBundle) {
        translation = [languageBundle localizedStringForKey:key value:@"" table:nil];
    }
    if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
        return value;
    }
    return translation ? translation : @"";
}
