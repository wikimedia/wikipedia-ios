//  Created by Adam Baso on 2/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikipediaAppUtils.h"
#import "AssetsFile.h"

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

+(NSString *)domainNameForCode:(NSString *)code
{
    AssetsFile *assetsFile = [[AssetsFile alloc] initWithFile:ASSETS_FILE_LANGUAGES];
    NSArray *result = assetsFile.array;
    if (result.count > 0) {
        for (NSDictionary *d in result) {
            if ([d[@"code"] isEqualToString:code]) {
                return d[@"name"];
            }
        }
        return nil;
    }else{
        return nil;
    }
}


+(NSString *)mainArticleTitleForCode:(NSString *)code
{
    AssetsFile *assetsFile = [[AssetsFile alloc] initWithFile:ASSETS_FILE_MAINPAGES];
    NSDictionary *mainPageNames = assetsFile.dictionary;
    return mainPageNames[code];
}

+(NSString *)wikiLangForSystemLang:(NSString *)code
{
    NSArray *bits = [code componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-_"]];
    NSString *base = bits[0];
    // @todo check for mismatches!
    return base;
}

#pragma mark Copy bundled assets folder and contents to app "AppData/Documents/assets/"

+(void)copyAssetsFolderToAppDataDocuments
{
    /*
     Some files need to be bunded with releases, but potentially updated between
     releases as well. These files are placed in the bundled "assets" directory,
     which is copied over to the "AppData/Documents/assets/" folder because the
     bundle cannot be written to by the running app.
     
     The files in "AppData/Documents/assets/" are then accessed instead of their
     bundled copies. This way, when newly downloaded versions overwrite the
     "AppData/Documents/assets/" files, the new versions actually get used.
     
     So, this method
     - Copies bundled assets folder over to "AppData/Documents/assets/"
     if it's not already there. (Fresh app install)
     
     - Copies new files that may be added to bundle assets folder over to
     "AppData/Documents/assets/". (App update including new bundled files)
     
     - Copies files that exist in both the bundle and
     "AppData/Documents/assets/" if the bundled file is newer. (App
     update to files which were bundled in previous release.) Note
     that when an app update is installed and the app files are written
     the creation and last modified dates of the bundled files are
     probably changed to the current timestamp, which means these
     updated files will as a matter of course always be newer than
     any files in "AppData/Documents/assets/". In other words, the
     date comparison check in this method is probably redundant as the
     bundled file is always newer.
     */
    
    NSString *folderName = @"assets";
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:folderName];
    NSString *bundledPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:folderName];
    
    void(^copy)(NSString *, NSString *) = ^void(NSString *path1, NSString *path2) {
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:path1 toPath:path2 error:&error];
        if (error) {
            NSLog(@"Could not copy '%@' to '%@'", path1, path2);
        }
    };
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsPath]){
        // "AppData/Documents/assets/" didn't exist so copy bundled assets folder and its contents over to "AppData/Documents/assets/"
        copy(bundledPath, documentsPath);
    }else{
        
        // "AppData/Documents/assets/" exists, so only copy new or *newer* bundled assets folder files over to "AppData/Documents/assets/"
        
        NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:bundledPath];
        NSString *fileName;
        while ((fileName = [dirEnum nextObject] )) {
            
            NSString *documentsFilePath = [documentsPath stringByAppendingPathComponent:fileName];
            NSString *bundledFilePath = [bundledPath stringByAppendingPathComponent:fileName];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:documentsFilePath]){
                // No file in "AppData/Documents/assets/" so copy from bundle
                copy(bundledFilePath, documentsFilePath);
            }else{
                // File exists in "AppData/Documents/assets/" so copy it if bundled file is newer
                NSError *error1 = nil, *error2 = nil;
                NSDictionary *fileInDocumentsAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:documentsFilePath error:&error1];
                NSDictionary *fileInBundleAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:bundledFilePath error:&error2];
                
                if (!error1 && !error1) {
                    
                    NSDate *date1 = (NSDate*)fileInBundleAttr[NSFileModificationDate];
                    NSDate *date2 = (NSDate*)fileInDocumentsAttr[NSFileModificationDate];
                    
                    if ([date1 timeIntervalSinceDate:date2] > 0) {
                        // Bundled file is newer.
                        
                        // Remove existing "AppData/Documents/assets/" file - otherwise the copy will fail.
                        NSError *error = nil;
                        [[NSFileManager defaultManager] removeItemAtPath:documentsFilePath error:&error];
                        
                        // Copy!
                        copy(bundledFilePath, documentsFilePath);
                    }
                }
            }
        }
    }
}

+(BOOL)isDeviceLanguageRTL
{
    // Official way to determine current device user interface direction:
    // "For iOS apps, to determine whether the language is right-to-left,
    // send userInterfaceLayoutDirection to the shared application object"
    // http://stackoverflow.com/a/25500099/135557
    return ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft);
}

+(NSTextAlignment)rtlSafeAlignment
{
    // The apple docs say NSTextAlignmentNatural is supported in iOS 6. Lies! Only true for
    // attributed strings :(
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return NSTextAlignmentNatural;
    }else{
        BOOL isRTL = [self isDeviceLanguageRTL];
        return isRTL ? NSTextAlignmentRight : NSTextAlignmentLeft;
    }
}

@end
