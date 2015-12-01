//
//  WMFListTransitionProvider.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMFArticleListTransition;

@protocol WMFArticleListTransitionProvider <NSObject>

- (WMFArticleListTransition*)listTransition;

@end
