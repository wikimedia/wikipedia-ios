//
//  WMFArticleNavigation.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticleNavigation <NSObject>

- (void)wmf_scrollToLink:(NSURL*)linkURL animated:(BOOL)animated;

- (void)wmf_scrollToFragment:(NSString*)fragment animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
