#import "WikipediaAppUtils.h"
#import "WMFAssetsFile.h"
#import "NSBundle+WMFInfoUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WikipediaAppUtils

+ (void)initialize {
    if (self == [WikipediaAppUtils class]) {
        [self copyAssetsFolderToAppDataDocuments];
    }
}

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:[self class] selector:@selector(didReceiveMemoryWarningWithNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

+ (NSString *)appVersion {
    return [[NSBundle mainBundle] wmf_versionForCurrentBundleIdentifier];
}

+ (NSString *)bundleID {
    return [[NSBundle mainBundle] wmf_bundleIdentifier];
}

+ (NSString *)formFactor {
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

+ (NSString *)versionedUserAgent {
    UIDevice *d = [UIDevice currentDevice];
    return [NSString stringWithFormat:@"WikipediaApp/%@ (%@ %@; %@)",
                                      [[NSBundle mainBundle] wmf_debugVersion],
                                      [d systemName],
                                      [d systemVersion],
                                      [self formFactor]];
}

static WMFAssetsFile *_Nullable languageFile = nil;

+ (void)didReceiveMemoryWarningWithNotification:(NSNotification *)note {
    languageFile = nil;
}

+ (NSString *)languageNameForCode:(NSString *)code {
    if (!languageFile) {
        languageFile = [[WMFAssetsFile alloc] initWithFileType:WMFAssetsFileTypeLanguages];
    }

    return [languageFile.array bk_match:^BOOL(NSDictionary *obj) {
        return [obj[@"code"] isEqualToString:code];
    }][@"name"];
}

+ (NSString *)assetsPath {
    return [[[NSFileManager defaultManager] wmf_containerPath] stringByAppendingPathComponent:@"assets"];
}

+ (NSString *)bundledAssetsPath {
    return [[NSBundle bundleWithIdentifier:@"org.wikimedia.WMF"] pathForResource:@"assets" ofType:nil];
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

    NSString *documentsPath = [self assetsPath];
    NSString *bundledPath = [self bundledAssetsPath];

    void (^copy)(NSString *, NSString *) = ^void(NSString *path1, NSString *path2) {
        NSError *error = nil;
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

        NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:bundledPath];
        NSString *fileName;
        while ((fileName = [dirEnum nextObject])) {
            NSString *documentsFilePath = [documentsPath stringByAppendingPathComponent:fileName];
            NSString *bundledFilePath = [bundledPath stringByAppendingPathComponent:fileName];

            if (![[NSFileManager defaultManager] fileExistsAtPath:documentsFilePath]) {
                // No file in "AppData/Documents/assets/" so copy from bundle
                copy(bundledFilePath, documentsFilePath);
            } else {
                // File exists in "AppData/Documents/assets/" so copy it if bundled file is newer
                NSError *docFilePathErr = nil, *bundledFilePathErr = nil;
                NSDictionary *fileInDocumentsAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:documentsFilePath error:&docFilePathErr];
                NSDictionary *fileInBundleAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:bundledFilePath error:&bundledFilePathErr];

                if (!docFilePathErr && !bundledFilePathErr) {
                    NSDate *bundledFileDate = (NSDate *)fileInBundleAttr[NSFileModificationDate];
                    NSDate *documentsFileDate = (NSDate *)fileInDocumentsAttr[NSFileModificationDate];

                    if ([bundledFileDate timeIntervalSinceDate:documentsFileDate] > 0) {
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

@end

NS_ASSUME_NONNULL_END
