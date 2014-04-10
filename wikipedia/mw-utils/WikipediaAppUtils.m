//  Created by Adam Baso on 2/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikipediaAppUtils.h"

@implementation WikipediaAppUtils

+(NSString*) appVersion
{
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    return [NSString stringWithFormat: @"iOS-%@-%@-%@",
            [appInfo objectForKey: @"CFBundleDisplayName"],
            [appInfo objectForKey:@"CFBundleShortVersionString"],
            [appInfo objectForKey: @"CFBundleVersion"]
            ];
}

+(NSString*) localizedStringForKey:(NSString *)key
{
    // Based on handy sample from http://stackoverflow.com/questions/3263859/localizing-strings-in-ios-default-fallback-language/8784451#8784451
    //
    // MWLocalizedString doesn't fall back on languages on a string-by-string
    // basis, so missing keys in a localization file give us the key name
    // instead of the English version we expected.
    //
    // If we get the key back, go load up the English bundle and fetch
    // the string from there instead.
    NSString *outStr = NSLocalizedString(key, nil);
    if ([outStr isEqualToString:key]) {
        // If we got the message key back, we have failed. :P
        // Note this isn't very efficient probably, but should
        // only be used in rare fallback cases anyway.
        NSString *path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        NSBundle *languageBundle = [NSBundle bundleWithPath:path];
        return [languageBundle localizedStringForKey:key value:@"" table:nil];
    } else {
        return outStr;
    }
}

@end
