
#import "WMFContentSource.h"

@interface WMFAnnouncementsContentSource : NSObject <WMFContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

@property (readonly, nonatomic, strong) WMFContentGroupDataStore *contentStore;

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore;

@end
