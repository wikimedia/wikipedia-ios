#import "ThumbnailFetcher.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+WMFExtras.h"

@interface ThumbnailFetcher ()

@property (nonatomic, strong) NSString *url;

@end

@implementation ThumbnailFetcher

- (instancetype)initAndFetchThumbnailFromURL:(NSString *)url
                                 withManager:(AFHTTPSessionManager *)manager
                          thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.url = url;
        self.fetchFinishedDelegate = delegate;
        [self fetchWithManager:manager];
    }
    return self;
}

- (void)fetchWithManager:(AFHTTPSessionManager *)manager {
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:self.url
        parameters:nil
        progress:NULL
        success:^(NSURLSessionDataTask *operation, id responseObject) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            NSError *error = nil;
            if (
                ![self isDataResponseValid:responseObject] ||
                !self.url ||
                (self.url.length == 0)) {
                NSString *errorUrl = self.url ? self.url : @"No URL specified.";
                error = [NSError errorWithDomain:@"Thumbnail Fetcher"
                                            code:THUMBNAIL_FETCH_ERROR_NOT_FOUND
                                        userInfo:@{ NSLocalizedDescriptionKey: [@"Thumbnail not retrieved. URL: " stringByAppendingString:errorUrl] }];
            }

            [self finishWithError:error
                      fetchedData:responseObject];
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            [self finishWithError:error
                      fetchedData:nil];
        }];
}

/*
   -(void)dealloc
   {
    NSLog(@"DEALLOC'ING THUMBNAIL FETCHER!");
   }
 */

@end
