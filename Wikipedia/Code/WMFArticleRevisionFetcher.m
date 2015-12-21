//
//  WMFArticleRevisionFetcher.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/16/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleRevisionFetcher.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "WMFMantleJSONResponseSerializer.h"
#import "WMFNetworkUtilities.h"

#import "WMFRevisionQueryResults.h"
#import "WMFArticleRevision.h"
#import "MWKTitle.h"

@interface WMFArticleRevisionFetcher ()
@property (nonatomic, strong) AFHTTPRequestOperationManager* requestManager;
@end

@implementation WMFArticleRevisionFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.requestManager                    = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        self.requestManager.responseSerializer =
            [WMFMantleJSONResponseSerializer serializerForArrayOf:[WMFRevisionQueryResults class]
                                                      fromKeypath:@"query.pages"];
    }
    return self;
}

- (AnyPromise*)fetchLatestRevisionsForTitle:(MWKTitle*)title
                                resultLimit:(NSUInteger)numberOfResults
                         endingWithRevision:(NSUInteger)revisionId {
    return [self.requestManager wmf_GETWithSite:title.site parameters:@{
                @"format": @"json",
                @"continue": @"",
                @"formatversion": @2,
                @"action": @"query",
                @"prop": @"revisions",
                @"titles": title.text,
                @"rvlimit": @(numberOfResults),
                @"rvendid": @(revisionId),
                @"rvprop": WMFJoinedPropertyParameters(@[@"ids", @"size", @"flags"])
            }].then(^(NSArray<WMFRevisionQueryResults*>* results) { return results.firstObject; });
}

@end
