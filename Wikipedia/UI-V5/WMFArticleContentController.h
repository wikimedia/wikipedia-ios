//
//  WMFArticleContentController.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWKArticle;

@protocol WMFArticleContentController <NSObject>

@property (nonatomic, strong, nullable) MWKArticle* article;

@end
