//
//  WMFFixtureRecording.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFFixtureRecording.h"

NS_ASSUME_NONNULL_BEGIN

#if DEBUG && TARGET_IPHONE_SIMULATOR

void _WMFRecordDataFixture(NSData* data, NSString* folder, NSString* filename) {
    _WMFRecordFixtureWithBlock(folder, filename, ^(NSString* path) {
        NSError* err;
        if (![data writeToFile:path options:0 error:&err]) {
            DDLogError(@"Failed to write fixture data to %@. %@", path, err);
        }
    });
}

void _WMFRecordFixtureWithBlock(NSString* folder,
                                NSString* filename,
                                WMFFixtureRecordingBlock block) {
    NSCParameterAssert(folder.length);
    NSCParameterAssert(filename.length);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"WMFFixtureRecordingEnabled"] || NSClassFromString(@"XCTestCase")) {
            return;
        }
        const char* const fixtureDir = getenv(WMFFixtureDirectoryEnvKey);
        if (fixtureDir) {
            NSString* fixtureFolderPath = [NSString stringWithFormat:@"%s/%@", fixtureDir, folder];
            NSError* err;
            if ([[NSFileManager defaultManager] createDirectoryAtPath:fixtureFolderPath
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:&err]) {
                block([fixtureFolderPath stringByAppendingPathComponent:filename]);
            } else {
                DDLogError(@"Failed to create fixture directory: %@", fixtureFolderPath);
            }
        }
    });
}

#endif

NS_ASSUME_NONNULL_END
