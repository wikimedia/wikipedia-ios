//
//  WMFExploreSectionSchema_Testing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/23/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

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
