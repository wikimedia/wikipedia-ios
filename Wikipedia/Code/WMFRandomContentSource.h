#import <Foundation/Foundation.h>
#import "WMFContentSource.h"

@class WMFContentGroupDataStore;
@class WMFArticleDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomContentSource : NSObject <WMFContentSource, WMFDateBasedContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
