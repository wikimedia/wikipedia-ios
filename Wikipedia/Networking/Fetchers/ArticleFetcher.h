//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

@class Article, AFHTTPRequestOperationManager, ArticleFetcher, MWKArticle;

@protocol ArticleFetcherDelegate <FetchFinishedDelegate>

@optional
- (void)articleFetcher:(ArticleFetcher*)savedArticlesFetcher
     didUpdateProgress:(CGFloat)progress;

@end


@interface ArticleFetcher : FetcherBase

@property (strong, nonatomic, readonly) MWKArticle* article;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchSectionsForArticle:(MWKArticle*)articleStore
                                   withManager:(AFHTTPRequestOperationManager*)manager
                            thenNotifyDelegate:(id<ArticleFetcherDelegate>)delegate;

@property (nonatomic, weak) id<ArticleFetcherDelegate> fetchFinishedDelegate;

@end
