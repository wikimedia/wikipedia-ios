//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryFetcher.h"
#import "AFHTTPSessionManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSString+WMFExtras.h"
#import "NSObject+WMFExtras.h"
#import "NSDate+Utilities.h"
#import "MediaWikiKit.h"
#import "WMFRevision.h"
#import <Mantle/Mantle.h>

@implementation PageHistoryFetcher

- (instancetype)initAndFetchHistoryForTitle:(MWKTitle*)title
                                withManager:(AFHTTPSessionManager*)manager
                         thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.fetchFinishedDelegate = delegate;
        [self fetchPageHistoryForTitle:title withManager:manager];
    }
    return self;
}

- (void)fetchPageHistoryForTitle:(MWKTitle*)title
                     withManager:(AFHTTPSessionManager*)manager {
    NSURL* url = [[SessionSingleton sharedInstance] urlForLanguage:title.site.language];

    NSDictionary* params = [self getParamsForTitle:title];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url.absoluteString parameters:params progress:NULL success:^(NSURLSessionDataTask* operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if (![responseObject isDict]) {
            responseObject = @{@"error": @{@"info": @"History not found."}};
        }

        //NSLog(@"PAGE HISTORY DATA RETRIEVED = %@", responseObject);

        // Handle case where response is received, but API reports error.
        // Uncomment @"rvdiffto": @(-1) in the parameters to force API error for testing.
        NSError* error = nil;
        if (responseObject[@"error"]) {
            NSMutableDictionary* errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Page History Fetcher" code:001 userInfo:errorDict];
        }

        NSArray* output = @[];
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        [self finishWithError:error
                  fetchedData:output];
    } failure:^(NSURLSessionDataTask* operation, NSError* error) {
        //NSLog(@"PAGE HISTORY FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError:error
                  fetchedData:nil];
    }];
}

- (NSDictionary*)getParamsForTitle:(MWKTitle*)title {
    NSMutableDictionary* params = @{
        @"action": @"query",
        @"prop": @"revisions",
        @"rvprop": @"ids|timestamp|user|size|parsedcomment",
        @"rvlimit": @51,
        @"rvdir": @"older",
        @"titles": title.text,
        @"continue": @"",
        @"format": @"json"
        //,@"rvdiffto": @(-1) // Add this to fake out "error" api response.
    }.mutableCopy;
    return params;
}

- (NSArray*)getSanitizedResponse:(NSDictionary*)rawResponse {
    NSMutableDictionary* revisionsByDay = @{}.mutableCopy;

    if (rawResponse.count > 0) {
        NSDictionary* pages = rawResponse[@"query"][@"pages"];
        if (pages) {
            for (NSDictionary* page in pages) {
                NSArray<WMFRevision*>* revs = [[MTLJSONAdapter arrayTransformerWithModelClass:[WMFRevision class]] transformedValue:pages[page][@"revisions"]];
                
                WMFRevision* earliestRevision = revs.lastObject;
                if (earliestRevision.parentID == 0) {
                    earliestRevision.revisionSize = earliestRevision.articleSizeAtRevision;
                    [self updateRevisionsByDay:revisionsByDay withRevision:earliestRevision];
                }
                
                for (NSInteger i = revs.count - 2; i >= 0; i--) {
                    WMFRevision* previous = revs[i + 1];
                    WMFRevision* current = revs[i];
                    current.revisionSize = current.articleSizeAtRevision - previous.articleSizeAtRevision;
                    [self updateRevisionsByDay:revisionsByDay withRevision:current];
                }
            }
        }
    }
    
    NSArray * sortedKeys = [[revisionsByDay allKeys] sortedArrayUsingSelector: @selector(compare:)];
    NSArray * objects = [revisionsByDay objectsForKeys: sortedKeys notFoundMarker: [NSNull null]];
    
    return objects;
}

- (void)updateRevisionsByDay:(NSMutableDictionary*)revisionsByDay withRevision:(WMFRevision*)revision {
    NSInteger distanceInDaysToDate = [revision daysFromToday];
    if (!revisionsByDay[@(distanceInDaysToDate)]) {
        revisionsByDay[@(distanceInDaysToDate)] = @[].mutableCopy;
    }
    
    NSMutableArray* revisionRowArray = revisionsByDay[@(distanceInDaysToDate)];
    [revisionRowArray addObject:revision];
}

@end
