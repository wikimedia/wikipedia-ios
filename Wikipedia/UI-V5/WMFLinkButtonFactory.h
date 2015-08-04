//
//  WMFMinimalArticleContentController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFArticleNavigationDelegate.h"
#import <DTCoreText/DTCoreText.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFLinkButtonFactory : NSObject
    <DTAttributedTextContentViewDelegate>

@property (nonatomic, weak, nullable) id<WMFArticleNavigationDelegate> articleNavigationDelegate;

@end

NS_ASSUME_NONNULL_END
