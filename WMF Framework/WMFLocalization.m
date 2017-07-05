#import <WMF/WMFLocalization.h>
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

- (nullable NSBundle *)wmf_fallbackLanguageBundle {
    static dispatch_once_t onceToken;
    static NSBundle *wmf_fallbackLanguageBundle;
    dispatch_once(&onceToken, ^{
        NSString *path = [self pathForResource:@"en" ofType:@"lproj"];
        wmf_fallbackLanguageBundle = [NSBundle bundleWithPath:path];
    });
    return wmf_fallbackLanguageBundle;
}

@end

NSString *WMFLocalizedStringWithDefaultValue(NSString *key, NSURL *_Nullable url, NSBundle *_Nullable bundle, NSString *value, NSString *comment) {
    if (bundle == nil) {
        bundle = NSBundle.wmf_localizationBundle;
    }
    
    NSString *language = url.wmf_language;
    NSString *translation = nil;
    if (language == nil) {
        translation = [bundle localizedStringForKey:key value:nil table:nil];
    } else {
        NSBundle *languageBundle = [bundle wmf_languageBundleForLanguage:language];
        translation = [languageBundle localizedStringForKey:key value:nil table:nil];
    }

    if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
        translation = [[bundle wmf_fallbackLanguageBundle] localizedStringForKey:key value:value table:nil];
    }
    
    return translation ? translation : @"";
}
