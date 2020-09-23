#import <WMF/WMFContentSource.h>

@class WMFSession;
@class WMFConfiguration;

@interface WMFAnnouncementsContentSource : NSObject <WMFContentSource, WMFOptionalNewContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL session:(WMFSession *)session configuration:(WMFConfiguration *)configuration;

@end
