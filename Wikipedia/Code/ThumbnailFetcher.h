#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, ThumbnailFetchErrorType) {
  THUMBNAIL_FETCH_ERROR_UNKNOWN = 0,
  THUMBNAIL_FETCH_ERROR_API = 1,
  THUMBNAIL_FETCH_ERROR_NOT_FOUND = 2
};

@class AFHTTPSessionManager;

@interface ThumbnailFetcher : FetcherBase

@property(nonatomic, strong, readonly) NSString *url;

// Kick-off method. Results are reported to "delegate" via the
// FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchThumbnailFromURL:(NSString *)url
                                 withManager:(AFHTTPSessionManager *)manager
                          thenNotifyDelegate:
                              (id<FetchFinishedDelegate>)delegate;
@end
