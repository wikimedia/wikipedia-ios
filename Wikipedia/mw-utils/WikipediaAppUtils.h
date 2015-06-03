//  Created by Adam Baso on 2/13/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NSObjectUtilities.h"
#import "NSString+WMFPageUtilities.h"

#define MWLocalizedString(key, throwaway) [WikipediaAppUtils localizedStringForKey : key]
#define MWCurrentArticleLanguageLocalizedString(key, throwaway) [WikipediaAppUtils currentArticleLanguageLocalizedString : key]

/// @return Number of bytes equivalent to `m` megabytes.
static NSUInteger MegabytesToBytes(NSUInteger m) {
    static NSUInteger const MEGABYTE = 1 << 20;
    return m * MEGABYTE;
}

@interface WikipediaAppUtils : NSObject

+ (NSString*)appVersion;
+ (NSString*)formFactor;
+ (NSString*)versionedUserAgent;
+ (NSString*)localizedStringForKey:(NSString*)key;
+ (NSString*)currentArticleLanguageLocalizedString:(NSString*)key;
+ (NSString*)relativeTimestamp:(NSDate*)date;
+ (NSString*)domainNameForCode:(NSString*)code;
+ (NSString*)wikiLangForSystemLang:(NSString*)code;
+ (BOOL)     isDeviceLanguageRTL;

+ (NSTextAlignment)rtlSafeAlignment;

+ (void)copyAssetsFolderToAppDataDocuments;

@end
