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

- (nonnull NSString *)wmf_languageBundleNameForWikipediaLanguage:(nonnull NSString *)language {
    NSString *bundleName = language;
    if ([language isEqualToString:@"zh"]) {
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
    } else if ([language isEqualToString:@"sr"]) {
        bundleName = @"sr-ec";
    } else if ([language isEqualToString:@"no"]) {
        bundleName = @"nb";
    }
    return bundleName;
}

- (nullable NSBundle *)wmf_languageBundleForWikipediaLanguage:(nonnull NSString *)language {
    NSMutableDictionary *bundles = [NSBundle wmf_languageBundles];
    NSBundle *bundle = bundles[language];
    if (!bundle) {
        NSString *languageBundleName = [self wmf_languageBundleNameForWikipediaLanguage:language];
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
            bundles[language] = bundle;
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
        NSBundle *languageBundle = [bundle wmf_languageBundleForWikipediaLanguage:wikipediaLanguage];
        translation = [languageBundle localizedStringForKey:key value:nil table:nil];
    }

    if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
        translation = [[bundle wmf_fallbackLanguageBundle] localizedStringForKey:key value:value table:nil];
    }

    return translation ? translation : @"";
}
