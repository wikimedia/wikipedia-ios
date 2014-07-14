//  Created by Adam Baso on 2/13/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

#define MWLocalizedString(key, throwaway) [WikipediaAppUtils localizedStringForKey:key]

@interface WikipediaAppUtils : NSObject

+(NSString*) appVersion;
+(NSString*) formFactor;
+(NSString*) versionedUserAgent;
+(NSString*) localizedStringForKey:(NSString *)key;
+(NSString*) relativeTimestamp:(NSDate *)date;
+(NSString*) domainNameForCode:(NSString *)code;
+(NSString*) mainArticleTitleForCode:(NSString *)code;
+(NSString*) wikiLangForSystemLang:(NSString *)code;
+(BOOL) isDeviceLanguageRTL;

+(void)copyAssetsFolderToAppDataDocuments;

@end
