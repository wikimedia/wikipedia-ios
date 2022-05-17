#import <WMF/WMFContentSource.h>

@class WMFNotificationsController;
@class MWKDataStore;
@class WMFFeedNewsStory;
@class WMFFeedDayResponse;
@class WMFArticle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentSource : NSObject <WMFContentSource, WMFDateBasedContentSource>

@property (readonly, nonatomic, strong) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)siteURL userDataStore:(MWKDataStore *)userDataStore;

- (instancetype)init NS_UNAVAILABLE;

//Use this method to fetch content directly. Using this will not persist the results
- (void)fetchContentForDate:(NSDate *)date force:(BOOL)force completion:(void (^)(WMFFeedDayResponse *__nullable feedResponse, NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *__nullable pageViews))completion;

@end

NS_ASSUME_NONNULL_END
