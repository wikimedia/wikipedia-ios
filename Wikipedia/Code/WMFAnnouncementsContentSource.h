#import <WMF/WMFContentSource.h>

@class MWKDataStore;
@class WKFundraisingCampaignDataController;
@class WKDonateDataController;

@interface WMFAnnouncementsContentSource : NSObject <WMFContentSource, WMFOptionalNewContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL userDataStore:(MWKDataStore *)userDataStore;

@end
