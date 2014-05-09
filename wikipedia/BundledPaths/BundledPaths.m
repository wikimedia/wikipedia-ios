//  Created by Monte Hurd on 5/9/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BundledPaths.h"
#import "BundledJson.h"

@implementation BundledPaths

+ (NSString *)nameForFile:(BundledJsonFile)bundledJsonFile
{
    switch (bundledJsonFile) {
        case BUNDLED_JSON_CONFIG:
            return @"ios.json";
            break;
        case BUNDLED_JSON_LANGUAGES:
            return @"languages.json";
            break;
        case BUNDLED_JSON_MAINPAGES:
            return @"mainpages.json";
            break;
        default:
            return BUNDLED_JSON_UNDEFINED;
            break;
    }
}

+ (NSString *)nameForPath:(BundledPath)bundledPath
{
    switch (bundledPath) {
        case BUNDLED_PATH_CONFIG:
            return @"config";
            break;
        case BUNDLED_PATH_LANGUAGES:
        case BUNDLED_PATH_MAINPAGES:
            return @"Languages";
            break;
        default:
            return BUNDLED_PATH_UNDEFINED;
            break;
    }
}

+ (BundledPath)bundledPathForFile:(BundledJsonFile)file
{
    switch (file) {
        case BUNDLED_JSON_CONFIG:
            return BUNDLED_PATH_CONFIG;
            break;
        case BUNDLED_JSON_LANGUAGES:
            return BUNDLED_PATH_LANGUAGES;
            break;
        case BUNDLED_JSON_MAINPAGES:
            return BUNDLED_PATH_MAINPAGES;
            break;
        default:
            return BUNDLED_PATH_UNDEFINED;
            break;
    }
}

+ (NSString *)remoteUrlForFile:(BundledJsonFile)bundledJsonFile
{
    // For now only the config file is remote synced.
    switch (bundledJsonFile) {
        case BUNDLED_JSON_CONFIG:
            return @"https://bits.wikimedia.org/static-current/extensions/MobileApp/config/ios.json";
            break;
        default:
            return @"";
            break;
    }
}

+(NSString *)pathForFolder:(BundledPath)folder file:(BundledJsonFile)file
{
    NSString *folderName = [self nameForPath:folder];
    NSString *fileName = [self nameForFile:file];
    NSArray *documentsPath = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *jsonPath = [[documentsPath objectAtIndex:0] stringByAppendingPathComponent:@"Json"];
    NSString *folderPath = [jsonPath stringByAppendingPathComponent:folderName];
    NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
    return filePath;
}

+ (NSString *)bundledJsonFilePath:(BundledJsonFile)file
{
    BundledPath bundledPath = [self bundledPathForFile:file];
    return [self pathForFolder:bundledPath file:file];
}

+ (NSURL *)bundledJsonFileRemoteUrl:(BundledJsonFile)file
{
    return [NSURL URLWithString:[self remoteUrlForFile:file]];
}

@end
