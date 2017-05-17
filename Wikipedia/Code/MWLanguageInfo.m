#import "MWLanguageInfo.h"

@implementation MWLanguageInfo

+ (MWLanguageInfo *)languageInfoForCode:(NSString *)code {
    MWLanguageInfo *languageInfo = [[MWLanguageInfo alloc] init];
    languageInfo.code = [MWLanguageInfo codeForCode:code];
    if ([[MWLanguageInfo rtlLanguages] containsObject:code]) {
        languageInfo.dir = @"rtl";
    } else {
        languageInfo.dir = @"ltr";
    }
    return languageInfo;
}

+ (BOOL)articleLanguageIsRTL:(nullable MWKArticle *)article {
    if (!article) {
        return NO;
    }
    return [[MWLanguageInfo languageInfoForCode:
             article.url.wmf_language]
            .dir
            isEqualToString:@"rtl"];
}

+ (NSString *)codeForCode:(NSString *)code {
    if ([code isEqualToString:@"test"]) {
        return @"en";
    } else if ([code isEqualToString:@"simple"]) {
        return @"en";
    } else {
        return code;
    }
}

+ (NSSet *)rtlLanguages {
    static dispatch_once_t onceToken;
    static NSSet *rtlLanguages;
    dispatch_once(&onceToken, ^{
        rtlLanguages = [NSSet setWithObjects:@"arc", @"arz", @"ar", @"bcc", @"bqi", @"ckb", @"dv", @"fa", @"glk", @"ha", @"he", @"khw", @"ks", @"mzn", @"pnb", @"ps", @"sd", @"ug", @"ur", @"yi", nil];
    });
    return rtlLanguages;
}

+ (UISemanticContentAttribute)semanticContentAttributeForWMFLanguage:(nullable NSString *)language {
    if (!language) {
        return UISemanticContentAttributeUnspecified;
    }
    return [[MWLanguageInfo rtlLanguages] containsObject:language] ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeForceLeftToRight;
}

@end
