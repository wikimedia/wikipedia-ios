//
//  WMFArticleRevisionFetcher.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/16/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMFArticleRevisionFetcher : NSObject

- (instancetype)init;

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval;

- (AnyPromise*)fetchLatestRevisionsForTitle:(MWKTitle*)title
                                resultLimit:(NSUInteger)numberOfResults
                         endingWithRevision:(NSUInteger)revisionId;

@end
