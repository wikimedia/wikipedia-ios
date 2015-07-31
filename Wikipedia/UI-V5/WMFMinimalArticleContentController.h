//
//  WMFMinimalArticleContentController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFArticleNavigationDelegate.h"

@class DTAttributedTextContentView;
@class DTAttributedTextCell;

NS_ASSUME_NONNULL_BEGIN

@interface WMFMinimalArticleContentController : NSObject

@property (nonatomic, weak, nullable) id<WMFArticleNavigationDelegate> articleNavigationDelegate;

- (void)configureContentView:(DTAttributedTextContentView*)contentView;

- (void)configureCell:(DTAttributedTextCell*)attributedTextCell;

@end

NS_ASSUME_NONNULL_END
