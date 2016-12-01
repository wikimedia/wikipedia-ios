#import "AssetsFileFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "WMFAssetsFile.h"

NSTimeInterval const kWMFMaxAgeDefault = 60 * 60 * 24;

@implementation AssetsFileFetcher

- (instancetype)initAndFetchAssetsFileOfType:(WMFAssetsFileType)file
                                 withManager:(AFHTTPSessionManager *)manager
                                      maxAge:(NSTimeInterval)maxAge {
    self = [super init];
    if (self) {
        self.fetchFinishedDelegate = nil;
        [self fetchAssetsFile:file
                       maxAge:maxAge
                  withManager:manager];
    }
    return self;
}

- (void)fetchAssetsFile:(WMFAssetsFileType)file
                 maxAge:(NSTimeInterval)maxAge
            withManager:(AFHTTPSessionManager *)manager;
{
    WMFAssetsFile *assetsFile = [[WMFAssetsFile alloc] initWithFileType:file];

    // Cancel the operation if the existing file hasn't aged enough.
    BOOL shouldRefresh = [assetsFile isOlderThan:maxAge];

    if (!shouldRefresh) {
        return;
    }

    NSURL *url = assetsFile.url;

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url.absoluteString
        parameters:nil
        progress:NULL
        success:^(NSURLSessionDataTask *operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            if ([operation.response isKindOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse *)operation.response statusCode] != 200) {
                return;
            }

            if (![self isDataResponseValid:responseObject]) {
                return;
            }

            NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];

            if ([responseString hasPrefix:@"/*\nInternal error\n*"]) {
                return;
            }

            NSError *error = nil;

            [responseString writeToFile:assetsFile.path
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:&error];
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            //NSLog(@"Error URL: %@", operation.request.URL);

            [[MWNetworkActivityIndicatorManager sharedManager] pop];
        }];
}

/*
   -(void)dealloc
   {
    NSLog(@"DEALLOC'ING ASSETS FILE FETCHER!");
   }
 */

@end
