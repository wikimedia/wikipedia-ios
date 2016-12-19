#import <Foundation/Foundation.h>

@class WMFAuthManagerInfo;

NS_ASSUME_NONNULL_BEGIN

typedef void (^WMFAuthManagerInfoBlock)(WMFAuthManagerInfo *info);

@interface WMFAuthManagerInfoFetcher : NSObject

- (void)fetchAuthManagerCreationAvailableForSiteURL:(NSURL *)siteURL success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure;
- (void)fetchAuthManagerLoginAvailableForSiteURL:(NSURL *)siteURL success:(WMFAuthManagerInfoBlock)success failure:(WMFErrorHandler)failure;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
