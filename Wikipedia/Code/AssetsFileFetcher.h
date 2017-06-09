#import <WMF/FetcherBase.h>

@class AFHTTPSessionManager;

/**
 *  Default max age for file before fetching
 */
extern NSTimeInterval const kWMFMaxAgeDefault;

@interface AssetsFileFetcher : FetcherBase

// Syncs a "/AppData/Documents/assets/" file with a remote file.
// Only does so if age of app file exceeds maxAge or if the file isn't
// found in app. Nice because we can sync assets files with any periodicity
// required just by firing these fetches off occasionally. Self-cancels
// if maxAge has not been exceeded.

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchAssetsFileOfType:(WMFAssetsFileType)file
                                 withManager:(AFHTTPSessionManager *)manager
                                      maxAge:(NSTimeInterval)maxAge;

@end
