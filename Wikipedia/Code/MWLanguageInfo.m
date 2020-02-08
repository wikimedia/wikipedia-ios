#import <WMF/MWLanguageInfo.h>
#import <WMF/NSURL+WMFLinkParsing.h>

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
        rtlLanguages = [NSSet setWithObjects:@"arc", @"arz", @"ar", @"azb", @"bcc", @"bqi", @"ckb", @"dv", @"fa", @"glk", @"lrc", @"he", @"khw", @"ks", @"mzn", @"nqo", @"pnb", @"ps", @"sd", @"ug", @"ur", @"yi", nil];
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
