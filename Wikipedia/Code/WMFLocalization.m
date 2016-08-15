#import "WMFLocalization.h"

NSString* localizedStringForKeyFallingBackOnEnglish(NSString* key){
    NSString* outStr = NSLocalizedString(key, nil);
    if (![outStr isEqualToString:key]) {
        return outStr;
    }

    static NSBundle* englishBundle = nil;

    if (!englishBundle) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        englishBundle = [NSBundle bundleWithPath:path];
    }
    return [englishBundle localizedStringForKey:key value:@"" table:nil];
}

NSString* localizedStringForURLWithKeyFallingBackOnEnglish(NSURL* url, NSString* key){
    NSString *language = url.wmf_language;
    if (language == nil) {
        language = @"en";
    }
    NSString* path           = [[NSBundle mainBundle] pathForResource:language ofType:@"lproj"];
    NSBundle* languageBundle = [NSBundle bundleWithPath:path];
    NSString* translation    = nil;
    if (languageBundle) {
        translation = [languageBundle localizedStringForKey:key value:@"" table:nil];
    }
    if (!translation || [translation isEqualToString:key] || (translation.length == 0)) {
        return MWLocalizedString(key, nil);
    }
    return translation;
}

