#import "WMFContentSource.h"

@interface WMFMainPageContentSource : NSObject <WMFContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL;

- (instancetype)init NS_UNAVAILABLE;

@end
