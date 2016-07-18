
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomArticleFetcher : NSObject

- (void)fetchRandomArticleWithDomainURL:(NSURL*)domainURL failure:(nonnull WMFErrorHandler)failure success:(nonnull WMFSearchResultHandler)success;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END