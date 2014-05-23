//  Created by Adam Baso on 2/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikipediaAppUtils.h"

@implementation WikipediaAppUtils

+(NSString*) appVersion
{
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    return [NSString stringWithFormat: @"%@", [appInfo objectForKey:@"CFBundleShortVersionString"]];
}

+(NSString*) formFactor
{
    UIUserInterfaceIdiom ff = UI_USER_INTERFACE_IDIOM();
    // We'll break; on each case, just to follow good form.
    switch (ff) {
        case UIUserInterfaceIdiomPad:
            return @"Tablet";
            break;
        case UIUserInterfaceIdiomPhone:
            return @"Phone";
            break;
        default:
            return @"Other";
            break;
    }
}

+(NSString*) versionedUserAgent
{
    UIDevice *d = [UIDevice currentDevice];
    return [NSString stringWithFormat:@"WikipediaApp/%@ (%@ %@; %@)",
            [self appVersion],
            [d systemName],
            [d systemVersion],
            [self formFactor]
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

+(NSString *) relativeTimestamp:(NSDate *)date
{
    NSTimeInterval interval = abs([date timeIntervalSinceNow]);
    double minutes = interval / 60.0;
    double hours = minutes / 60.0;
    double days = hours / 24.0;
    double months = days / (365.25 / 12.0);
    double years = months / 12.0;
    
    if (minutes < 2.0) {
        return MWLocalizedString(@"timestamp-just-now", nil);
    } else if (hours < 2.0) {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-minutes", nil), (int)round(minutes)];
    } else if (days < 2.0) {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-hours", nil), (int)round(hours)];
    } else if (months < 2.0) {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-days", nil), (int)round(days)];
    } else if (months < 24.0) {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-months", nil), (int)round(months)];
    } else {
        return [NSString stringWithFormat:MWLocalizedString(@"timestamp-years", nil), (int)round(years)];
    }
}

@end
