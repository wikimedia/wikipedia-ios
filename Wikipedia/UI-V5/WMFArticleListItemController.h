//
//  WMFArticleListItemController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger, WMFArticleControllerMode) {
    WMFArticleControllerModeNormal = 0,
    WMFArticleControllerModeList,
    WMFArticleControllerModePopup,
};

@protocol WMFArticleListItemController <NSObject>

- (WMFArticleControllerMode)mode;

- (void)setMode:(WMFArticleControllerMode)mode animated:(BOOL)animated;

@end
