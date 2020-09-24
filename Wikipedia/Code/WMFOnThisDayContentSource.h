#import <WMF/WMFContentSource.h>

@class WMFSession;
@class WMFConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface WMFOnThisDayContentSource : NSObject <WMFContentSource, WMFDateBasedContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL session:(WMFSession *)session configuration:(WMFConfiguration *)configuration;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
