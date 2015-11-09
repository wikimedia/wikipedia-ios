//
//  WMFFeedItemExtractFetcher.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnyPromise;

NS_ASSUME_NONNULL_BEGIN

@interface WMFENFeaturedTitleFetcher : NSObject

- (AnyPromise*)featuredArticlePreviewForDate:(nullable NSDate*)date;

@end

NS_ASSUME_NONNULL_END
