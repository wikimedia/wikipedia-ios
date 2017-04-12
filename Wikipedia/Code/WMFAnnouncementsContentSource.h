#import "WMFContentSource.h"

@interface WMFAnnouncementsContentSource : NSObject <WMFContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL;

@end
