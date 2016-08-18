#import "WMFExploreSectionSchema.h"

@class WMFLocationManager;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreSectionSchema ()

+ (instancetype)schemaWithSiteURL:(NSURL*)siteURL
                         savedPages:(MWKSavedPageList*)savedPages
                            history:(MWKHistoryList*)history
                          blackList:(WMFRelatedSectionBlackList*)blackList
                    locationManager:(WMFLocationManager*)locationManager
                               file:(NSURL*)fileURL;

- (AnyPromise*)save;

@end

NS_ASSUME_NONNULL_END
