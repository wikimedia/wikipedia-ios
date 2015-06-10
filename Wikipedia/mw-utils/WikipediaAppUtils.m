//  Created by Adam Baso on 2/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikipediaAppUtils.h"
#import "WMFAssetsFile.h"
#import "SessionSingleton.h"
#import "NSBundle+WMFInfoUtils.h"
#import <BlocksKit/BlocksKit.h>

NSUInteger MegabytesToBytes(NSUInteger m) {
    static NSUInteger const MEGABYTE = 1 << 20;
    return m * MEGABYTE;
}

@implementation WikipediaAppUtils

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:[self class] selector:@selector(didReceiveMemoryWarningWithNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

+ (NSString*)appVersion {
    return [[NSBundle mainBundle] wmf_versionForCurrentBundleIdentifier];
}

+ (NSString*)bundleID {
    return [[NSBundle mainBundle] wmf_bundleIdentifier];
}

+ (NSString*)formFactor {
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

+ (NSString*)versionedUserAgent {
    UIDevice* d = [UIDevice currentDevice];
    return [NSString stringWithFormat:@"WikipediaApp/%@ (%@ %@; %@)",
            [[NSBundle mainBundle] wmf_debugVersion],
            [d systemName],
            [d systemVersion],
            [self formFactor]
    ];
}

+ (NSString*)currentArticleLanguageLocalizedString:(NSString*)key {
    MWKSite* site            = [SessionSingleton sharedInstance].currentArticleSite;
    NSString* path           = [[NSBundle mainBundle] pathForResource:site.language ofType:@"lproj"];
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

+ (NSString*)relativeTimestamp:(NSDate*)date {
    NSTimeInterval interval = fabs([date timeIntervalSinceNow]);
    double minutes          = interval / 60.0;
    double hours            = minutes / 60.0;
    double days             = hours / 24.0;
    double months           = days / (365.25 / 12.0);
    double years            = months / 12.0;

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

static WMFAssetsFile* languageFile = nil;

+ (void)didReceiveMemoryWarningWithNotification:(NSNotification*)note {
    languageFile = nil;
}

+ (NSString*)domainNameForCode:(NSString*)code {
    if (!languageFile) {
        languageFile = [[WMFAssetsFile alloc] initWithFileType:WMFAssetsFileTypeLanguages];
    }

    return [languageFile.array bk_match:^BOOL (NSDictionary* obj) {
        if ([obj[@"code"] isEqualToString:code]) {
            return YES;
        }

        return NO;
    }][@"name"];
}

+ (NSString*)wikiLangForSystemLang:(NSString*)code {
    NSArray* bits  = [code componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-_"]];
    NSString* base = bits[0];
    // @todo check for mismatches!
    return base;
}

#pragma mark Copy bundled assets folder and contents to app "AppData/Documents/assets/"

+ (void)copyAssetsFolderToAppDataDocuments {
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

    NSString* folderName    = @"assets";
    NSArray* paths          = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:folderName];
    NSString* bundledPath   = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:folderName];

    void (^ copy)(NSString*, NSString*) = ^void (NSString* path1, NSString* path2) {
        NSError* error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:path1 toPath:path2 error:&error];
        if (error) {
            NSLog(@"Could not copy '%@' to '%@'", path1, path2);
        }
    };

    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsPath]) {
        // "AppData/Documents/assets/" didn't exist so copy bundled assets folder and its contents over to "AppData/Documents/assets/"
        copy(bundledPath, documentsPath);
    } else {
        // "AppData/Documents/assets/" exists, so only copy new or *newer* bundled assets folder files over to "AppData/Documents/assets/"

        NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:bundledPath];
        NSString* fileName;
        while ((fileName = [dirEnum nextObject])) {
            NSString* documentsFilePath = [documentsPath stringByAppendingPathComponent:fileName];
            NSString* bundledFilePath   = [bundledPath stringByAppendingPathComponent:fileName];

            if (![[NSFileManager defaultManager] fileExistsAtPath:documentsFilePath]) {
                // No file in "AppData/Documents/assets/" so copy from bundle
                copy(bundledFilePath, documentsFilePath);
            } else {
                // File exists in "AppData/Documents/assets/" so copy it if bundled file is newer
                NSError* docFilePathErr           = nil, * bundledFilePathErr = nil;
                NSDictionary* fileInDocumentsAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:documentsFilePath error:&docFilePathErr];
                NSDictionary* fileInBundleAttr    = [[NSFileManager defaultManager] attributesOfItemAtPath:bundledFilePath error:&bundledFilePathErr];

                if (!docFilePathErr && !bundledFilePathErr) {
                    NSDate* bundledFileDate   = (NSDate*)fileInBundleAttr[NSFileModificationDate];
                    NSDate* documentsFileDate = (NSDate*)fileInDocumentsAttr[NSFileModificationDate];

                    if ([bundledFileDate timeIntervalSinceDate:documentsFileDate] > 0) {
                        // Bundled file is newer.

                        // Remove existing "AppData/Documents/assets/" file - otherwise the copy will fail.
                        NSError* error = nil;
                        [[NSFileManager defaultManager] removeItemAtPath:documentsFilePath error:&error];

                        // Copy!
                        copy(bundledFilePath, documentsFilePath);
                    }
                }
            }
        }
    }
}

+ (BOOL)isDeviceLanguageRTL {
    // Official way to determine current device user interface direction:
    // "For iOS apps, to determine whether the language is right-to-left,
    // send userInterfaceLayoutDirection to the shared application object"
    // http://stackoverflow.com/a/25500099/135557
    return ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft);
}

@end
