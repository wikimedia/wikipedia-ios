//  Created by Brion on 3/12/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWLanguageInfo.h"

@implementation MWLanguageInfo

NSArray* rtlLanguages;

+ (MWLanguageInfo*)languageInfoForCode:(NSString*)code {
    MWLanguageInfo* languageInfo = [[MWLanguageInfo alloc] init];
    languageInfo.code = [MWLanguageInfo codeForCode:code];
    if ([[MWLanguageInfo rtlLanguages] containsObject:code]) {
        languageInfo.dir = @"rtl";
    } else {
        languageInfo.dir = @"ltr";
    }
    return languageInfo;
}

+ (BOOL)articleLanguageIsRTL:(MWKArticle*)article {
    return [[MWLanguageInfo languageInfoForCode:
             article.title.site.language].dir
            isEqualToString:@"rtl"];
}

+ (NSString*)codeForCode:(NSString*)code {
    if ([code isEqualToString:@"test"]) {
        return @"en";
    } else if ([code isEqualToString:@"simple"]) {
        return @"en";
    } else {
        return code;
    }
}

+ (NSArray*)rtlLanguages {
    if (rtlLanguages == nil) {
        rtlLanguages = @[@"arc", @"arz", @"ar", @"bcc", @"bqi", @"ckb", @"dv", @"fa", @"glk", @"ha", @"he",
                         @"khw", @"ks", @"mzn", @"pnb", @"ps", @"sd", @"ug", @"ur", @"yi"];
    }
    return rtlLanguages;
}

@end
