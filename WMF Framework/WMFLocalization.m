#import "WMFLocalization.h"
#import <WMF/WMF-Swift.h>

@implementation NSBundle (WMFLocalization)

+ (NSBundle *)wmf_localizationBundle {
    return [NSBundle wmf];
}

+ (nonnull NSMutableDictionary *)wmf_languageBundles {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *wmf_languageBundles;
    dispatch_once(&onceToken, ^{
        wmf_languageBundles = [NSMutableDictionary new];
    });
    return wmf_languageBundles;
}


- (nullable NSBundle *)wmf_languageBundleForLanguage:(nonnull NSString *)language {
    NSMutableDictionary *bundles = [NSBundle wmf_languageBundles];
    NSString *path = [self pathForResource:language ofType:@"lproj"];
    NSBundle *bundle = bundles[path];
    if (!bundle) {
        bundle = [NSBundle bundleWithPath:path];
        if (bundle) {
            bundles[path] = bundle;
        }
    }
    return bundle;
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

    NSBundle *languageBundle = [bundle wmf_languageBundleForLanguage:language];
    NSString *translation = nil;
    if (languageBundle) {
        translation = [languageBundle localizedStringForKey:key value:@"" table:nil];
    }
    if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
        return NSLocalizedStringWithDefaultValue(key, nil, bundle, value, comment);
    }
    return translation ? translation : @"";
}
