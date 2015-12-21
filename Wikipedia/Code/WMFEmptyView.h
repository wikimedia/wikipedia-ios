//
//  WMFEmptyView.h
//  Wikipedia
//
//  Created by Corey Floyd on 12/10/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMFEmptyView : UIView

+ (instancetype)noFeedEmptyView;
+ (instancetype)noArticleEmptyView;
+ (instancetype)noSearchResultsEmptyView;
+ (instancetype)noSavedPagesEmptyView;
+ (instancetype)noHistoryEmptyView;

@end
