//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

@class AFHTTPRequestOperationManager, ArticleFetcher, AFHTTPRequestOperation, MWKTitle;


@protocol ArticleFetcherDelegate <FetchFinishedDelegate>

@optional
- (void)articleFetcher:(ArticleFetcher*)savedArticlesFetcher
     didUpdateProgress:(CGFloat)progress;

@end


@interface ArticleFetcher : FetcherBase

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;
@property (nonatomic, strong, readonly) MWKTitle* title;

- (AFHTTPRequestOperation*)fetchSectionsForTitle:(MWKTitle*)title
                                     inDataStore:(MWKDataStore*)store
                                     withManager:(AFHTTPRequestOperationManager*)manager
                              thenNotifyDelegate:(id<ArticleFetcherDelegate>)delegate;

@property (nonatomic, weak) id<ArticleFetcherDelegate> fetchFinishedDelegate;

@end
