//
//  WMFArticleContainerViewController_Private.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/23/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleContainerViewController.h"

@class WMFTableOfContentsViewController, WebViewController;

typedef NS_ENUM (NSInteger, WMFArticleFooterViewIndex) {
    WMFArticleFooterViewIndexReadMore = 0
};

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleContainerViewController ()

// Data
@property (nonatomic, strong, readwrite, nullable) MWKArticle* article;

// Children
@property (nonatomic, strong, nullable) WMFTableOfContentsViewController* tableOfContentsViewController;
@property (nonatomic, strong) WebViewController* webViewController;

@end

NS_ASSUME_NONNULL_END
