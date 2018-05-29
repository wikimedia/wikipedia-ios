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
    NSBundle *bundle = bundles[language];
    if (!bundle) {
        if ([language isEqualToString:@"zh"]) {
            language = @"zh-Hans";
            for (NSString *code in [NSLocale wmf_preferredLanguageCodes]) {
                if (![code hasPrefix:@"zh"]) {
                    continue;
                }
                NSArray<NSString *> *components = [code componentsSeparatedByString:@"-"];
                if ([components count] > 1) {
                    language = [@[components[0], [components[1] capitalizedStringWithLocale:[NSLocale localeWithLocaleIdentifier:@"en"]]] componentsJoinedByString:@"-"];
                    break;
                }

            }
        }
        NSString *path = [self pathForResource:language ofType:@"lproj"];
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

NSString *WMFLocalizedStringWithDefaultValue(NSString *key, NSString *_Nullable wikipediaLanguage, NSBundle *_Nullable bundle, NSString *value, NSString *comment) {
    if (bundle == nil) {
        bundle = NSBundle.wmf_localizationBundle;
    }

    NSString *translation = nil;
    if (wikipediaLanguage == nil) {
        translation = [bundle localizedStringForKey:key value:nil table:nil];
    } else {
        NSBundle *languageBundle = [bundle wmf_languageBundleForLanguage:wikipediaLanguage];
        translation = [languageBundle localizedStringForKey:key value:nil table:nil];
    }

    if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
        translation = [[bundle wmf_fallbackLanguageBundle] localizedStringForKey:key value:value table:nil];
    }

    return translation ? translation : @"";
}
