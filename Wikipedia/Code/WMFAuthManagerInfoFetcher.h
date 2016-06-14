
#import <Foundation/Foundation.h>

@class AnyPromise;
@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFAuthManagerInfoFetcher : NSObject

- (AnyPromise*)fetchAuthManagerCreationAvailableForSite:(MWKSite*)site;
- (AnyPromise*)fetchAuthManagerLoginAvailableForSite:(MWKSite*)site;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END