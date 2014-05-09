//  Created by Monte Hurd on 5/9/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BundledJson.h"
#import "BundledPaths.h"

@implementation BundledJson

+ (NSDictionary *)dictionaryFromBundledJsonFile:(BundledJsonFile)file
{
    NSError *error = nil;
    NSData *fileData = [NSData dataWithContentsOfFile:[BundledPaths bundledJsonFilePath:file] options:0 error:&error];
    if (error) return @{};
    error = nil;
    NSMutableDictionary *result = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&error];
    return (error) ? @{}: result;
}

+ (NSArray *)arrayFromBundledJsonFile:(BundledJsonFile)file
{
    NSError *error = nil;
    NSData *fileData = [NSData dataWithContentsOfFile:[BundledPaths bundledJsonFilePath:file] options:0 error:&error];
    if (error) return @[];
    error = nil;
    NSArray *result = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&error];
    return (error) ? @[]: result;
}

// Returns YES if the local version of the config file doesn't exist or is older than maxAge.
+ (BOOL)isRefreshNeededForBundledJsonFile:(BundledJsonFile)file maxAge:(CGFloat)maxAge
{
    NSString *path = [BundledPaths bundledJsonFilePath:file];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NO];
    if (!fileExists){
        NSLog(@"REFRESH NEEDED");
        return YES;
    }
    
    NSDate *lastModified = nil;
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:path];
    [url getResourceValue: &lastModified
                   forKey: NSURLContentModificationDateKey
                    error: &error];
    if (!error){
        NSTimeInterval currentAge = [[NSDate date] timeIntervalSinceDate:lastModified];
        NSLog(@"currentAge = %f maxAge = %f", currentAge, maxAge);
        if (currentAge > maxAge){
            NSLog(@"REFRESH NEEDED");
            return YES;
        }
    }
    NSLog(@"NO REFRESH NEEDED");
    return NO;
}

@end
