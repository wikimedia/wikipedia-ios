#import <WMF/WMFContentSource.h>

@class MWKDataStore;
@class WMFFundraisingCampaignDataControllerObjCBridge;

@interface WMFAnnouncementsContentSource : NSObject <WMFContentSource, WMFOptionalNewContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL userDataStore:(MWKDataStore *)userDataStore;

@end
