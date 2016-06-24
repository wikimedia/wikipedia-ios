
#import <Foundation/Foundation.h>

@class AnyPromise;
@class MWKSite;
@class WMFAuthManagerInfo;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ WMFAuthManagerInfoBlock)(WMFAuthManagerInfo* info);

@interface WMFAuthManagerInfoFetcher : NSObject

- (void)fetchAuthManagerCreationAvailableForSite:(MWKSite*)site success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure;
- (void)fetchAuthManagerLoginAvailableForSite:(MWKSite*)site success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END