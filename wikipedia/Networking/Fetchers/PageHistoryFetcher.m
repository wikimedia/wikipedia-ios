//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSString+Extras.h"
#import "NSObject+Extras.h"
#import "NSDate-Utilities.h"

@implementation PageHistoryFetcher

-(instancetype)initAndFetchHistoryForTitle: (MWKTitle *)title
                               withManager: (AFHTTPRequestOperationManager *)manager
                        thenNotifyDelegate: (id <FetchFinishedDelegate>) delegate
{
    self = [super init];
    if (self) {
        self.fetchFinishedDelegate = delegate;
        [self fetchPageHistoryForTitle:title withManager:manager];
    }
    return self;
}

- (void)fetchPageHistoryForTitle: (MWKTitle *)title
                     withManager: (AFHTTPRequestOperationManager *)manager
{

    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:title.site.language];

    NSDictionary *params = [self getParamsForTitle:title];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"History not found."}};
        }
        
        //NSLog(@"PAGE HISTORY DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        // Uncomment @"rvdiffto": @(-1) in the parameters to force API error for testing.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Page History Fetcher" code:001 userInfo:errorDict];
        }

        NSMutableArray *output = @[].mutableCopy;
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"PAGE HISTORY FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSDictionary *)getParamsForTitle:(MWKTitle *)title
{
    NSMutableDictionary *params = @{
                                    @"action": @"query",
                                    @"prop": @"revisions",
                                    @"rvprop": @"ids|timestamp|user|size|parsedcomment",
                                    @"rvlimit": @50,
                                    @"rvdir": @"older",
                                    @"titles": title.prefixedText,
                                    @"format": @"json"
                                    //,@"rvdiffto": @(-1) // Add this to fake out "error" api response.
                                    }.mutableCopy;
    return params;
}

-(NSMutableArray *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    NSMutableArray *output = @[].mutableCopy;
    NSMutableDictionary *parentSizes = @{}.mutableCopy;
    NSMutableDictionary *revisionsByDay = @{}.mutableCopy;
    
    if (rawResponse.count > 0) {
        NSDictionary *pages = rawResponse[@"query"][@"pages"];
        if (pages) {
            for (NSDictionary *page in pages) {
                NSString *title = pages[page][@"title"];
                for (NSDictionary *revision in pages[page][@"revisions"]) {
                    NSMutableDictionary *mutableRevision = revision.mutableCopy;
                    mutableRevision[@"title"] = title;
                    
                    parentSizes[revision[@"revid"]] = revision[@"size"];
                    
                    NSString *timeStampString = mutableRevision[@"timestamp"];
                    NSDate *timeStampDate = [timeStampString getDateFromIso8601DateString];
                    
                    NSUInteger distanceInDaysToDate = [timeStampDate distanceInDaysToDate:[NSDate date]];
                    
                    //NSLog(@"distanceInDaysToDate = %d", [timeStampDate distanceInDaysToDate:[NSDate date]]);
                    if (!revisionsByDay[@(distanceInDaysToDate)]) {
                        revisionsByDay[@(distanceInDaysToDate)] = @[].mutableCopy;
                    }
                    
                    NSMutableArray *revisionRowArray = revisionsByDay[@(distanceInDaysToDate)];
                    [revisionRowArray addObject:mutableRevision];
                }
            }
            
            NSMutableArray *revisionsByDaySorted = @[].mutableCopy;
            for (NSNumber *day in [revisionsByDay.allKeys sortedArrayUsingSelector: @selector(compare:)]){
                [revisionsByDaySorted addObject:@{
                                                  @"daysAgo": day,
                                                  @"revisions": revisionsByDay[day]
                                                  }];
            }
            
            [self calculateCharacterDeltasForRevisions: revisionsByDaySorted
                                       fromParentSizes: parentSizes];
            
            output = revisionsByDaySorted;
        }
    }
    return output;
}

-(void)calculateCharacterDeltasForRevisions:(NSMutableArray *)revisions fromParentSizes:(NSDictionary *)parentSizes
{
    // Note: always retrieve one more than you're going to show so the oldest item
    // shown can have it's characterDelta calculated.

    for (NSDictionary *day in revisions) {
        for (NSMutableDictionary *revision in day[@"revisions"]) {
            NSNumber *parentId = revision[@"parentid"];
            if(parentSizes[parentId]){
                NSNumber *parentSize = parentSizes[parentId];
                NSNumber *revisionSize = revision[@"size"];
                revision[@"characterDelta"] = @(revisionSize.integerValue - parentSize.integerValue);
            }else if (parentId){
                if (parentId.integerValue == 0) {
                    revision[@"characterDelta"] = revision[@"size"];
                }
            }
        }
    }
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING PAGE HISTORY FETCHER!");
}
*/

@end
