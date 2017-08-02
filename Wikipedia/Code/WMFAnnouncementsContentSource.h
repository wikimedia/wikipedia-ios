#import <WMF/WMFContentSource.h>

@interface WMFAnnouncementsContentSource : NSObject <WMFContentSource, WMFOptionalNewContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL;

@end
