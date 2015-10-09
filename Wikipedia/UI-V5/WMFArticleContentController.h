//
//  WMFArticleContentController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"

@class MWKArticle;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticleContentController <NSObject>

- (void)setArticle:(MWKArticle*)article discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;

@end

NS_ASSUME_NONNULL_END
