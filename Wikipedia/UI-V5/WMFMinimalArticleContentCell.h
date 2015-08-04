//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import <DTCoreText/DTCoreText.h>
#import "WMFArticleNavigationDelegate.h"

@interface WMFMinimalArticleContentCell : DTAttributedTextCell

@property (nonatomic, weak, nullable) id<WMFArticleNavigationDelegate> articleNavigationDelegate;

@end
