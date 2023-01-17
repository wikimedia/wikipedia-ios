#import <WMF/WMFLocalization.h>
#import <WMF/WMF-Swift.h>

@implementation NSBundle (WMFLocalization)

// A mapping of language variant content codes to available native `NSLocale` bundle identifiers. The values map to existing .lproj folders.
NSDictionary<NSString*, NSString*> *variantContentCodeToLocalizationBundleMapping = @{
    // Chinese variants
    @"zh-hk": @"zh-hant",
    @"zh-mo": @"zh-hant",
    @"zh-my": @"zh-hans",
    @"zh-sg": @"zh-hans",
    @"zh-tw": @"zh-hant",

    // Serbian variants
    // no-op - both variants are natively available iOS localizations

    // Kurdish variants
    @"ku-arab": @"ckb",

    // Tajik variants
    @"tg-latn": @"tg",

    // Uzbek variants
    @"uz-cyrl": @"uz",
};

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

- (nonnull NSString *)wmf_languageBundleNameForWikipediaLanguageCode:(nonnull NSString *)languageCode {
    NSString *bundleName = languageCode;
    if ([variantContentCodeToLocalizationBundleMapping valueForKey:languageCode]) {
        bundleName = [variantContentCodeToLocalizationBundleMapping valueForKey:languageCode];
    } else if ([languageCode isEqualToString:@"zh"]) {
        bundleName = @"zh-hans";
        for (NSString *code in [NSLocale wmf_preferredLanguageCodes]) {
            if (![code hasPrefix:@"zh"]) {
                continue;
            }
            NSArray<NSString *> *components = [code componentsSeparatedByString:@"-"];
            if ([components count] == 2) {
                bundleName = [code lowercaseString];
                break;
            }
        }
    } else if ([languageCode isEqualToString:@"sr"]) {
        bundleName = @"sr-ec";
    } else if ([languageCode isEqualToString:@"no"]) {
        bundleName = @"nb";
    }
    return bundleName;
}

- (nullable NSBundle *)wmf_languageBundleForWikipediaLanguageCode:(nonnull NSString *)languageCode {
    NSMutableDictionary *bundles = [NSBundle wmf_languageBundles];
    NSBundle *bundle = bundles[languageCode];
    if (!bundle) {
        NSString *languageBundleName = [self wmf_languageBundleNameForWikipediaLanguageCode:languageCode];
        NSArray *paths = [self pathsForResourcesOfType:@"lproj" inDirectory:nil];
        NSString *filename = [[languageBundleName lowercaseString] stringByAppendingPathExtension:@"lproj"];
        NSString *path = nil;
        for (NSString *possiblePath in paths) {
            if (![[possiblePath lowercaseString] hasSuffix:filename]) {
                continue;
            }
            path = possiblePath;
            break;
        }
        if (!path) {
            return nil;
        }
        bundle = [NSBundle bundleWithPath:path];
        if (bundle) {
            bundles[languageCode] = bundle;
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

NSString *WMFLocalizedStringWithDefaultValue(NSString *key, NSString *_Nullable wikipediaLanguageCode, NSBundle *_Nullable bundle, NSString *value, NSString *comment) {
    if (bundle == nil) {
        bundle = NSBundle.wmf_localizationBundle;
    }

    NSString *translation = nil;
    if (wikipediaLanguageCode == nil) {
        translation = [bundle localizedStringForKey:key value:nil table:nil];
    } else {
        NSBundle *languageBundle = [bundle wmf_languageBundleForWikipediaLanguageCode:wikipediaLanguageCode];
        translation = [languageBundle localizedStringForKey:key value:nil table:nil];
        
        if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
            translation = [bundle localizedStringForKey:key value:nil table:nil];
        }
    }

    if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
        translation = [[bundle wmf_fallbackLanguageBundle] localizedStringForKey:key value:value table:nil];
    }

    return translation ? translation : @"";
}
