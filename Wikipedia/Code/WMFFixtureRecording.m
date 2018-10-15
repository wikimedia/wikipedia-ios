#import "WMFFixtureRecording.h"
@import WMF.Swift;
@import WMF.WMFLogging;

NS_ASSUME_NONNULL_BEGIN

#if DEBUG && TARGET_IPHONE_SIMULATOR

void _WMFRecordDataFixture(NSData *data, NSString *folder, NSString *filename) {
    _WMFRecordFixtureWithBlock(folder, filename, ^(NSString *path) {
        NSError *err;
        if (![data writeToFile:path options:0 error:&err]) {
            DDLogError(@"Failed to write fixture data to %@. %@", path, err);
        }
    });
}

void _WMFRecordFixtureWithBlock(NSString *folder,
                                NSString *filename,
                                WMFFixtureRecordingBlock block) {
    if (folder.length == 0 || filename.length == 0) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (![[NSUserDefaults wmf] boolForKey:@"WMFFixtureRecordingEnabled"] || NSClassFromString(@"XCTestCase")) {
            return;
        }
        const char *const fixtureDir = getenv(WMFFixtureDirectoryEnvKey);
        if (fixtureDir) {
            NSString *fixtureFolderPath = [NSString stringWithFormat:@"%s/%@", fixtureDir, folder];
            NSError *err;
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
