//
//  WMFFeedItemExtractFetcher.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnyPromise, MWKSite;

NS_ASSUME_NONNULL_BEGIN

@interface WMFENFeaturedTitleFetcher : NSObject

- (AnyPromise*)fetchFeedItemTitleForSite:(MWKSite*)site date:(nullable NSDate*)date;

@end

NS_ASSUME_NONNULL_END
