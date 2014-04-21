//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "Defines.h"
#import "NSString+Extras.h"
#import "NSDate-Utilities.h"

@implementation PageHistoryOp

- (id)initWithDomain: (NSString *)domain
               title: (NSString *)title
     completionBlock: (void (^)(NSMutableArray *))completionBlock
      cancelledBlock: (void (^)(NSError *))cancelledBlock
          errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
    
        __weak PageHistoryOp *weakSelf = self;
        
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
            
            NSMutableDictionary *parameters = [@{
                                                 @"action": @"query",
                                                 @"prop": @"revisions",
                                                 @"action": @"query",
                                                 @"rvprop": @"ids|timestamp|user|size|parsedcomment",
                                                 @"rvlimit": @50,
                                                 @"rvdir": @"older",
                                                 @"titles": title,
                                                 @"format": @"json"
                                                 } mutableCopy];
            
            //NSLog(@"parameters = %@", parameters);
            
            weakSelf.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:[SessionSingleton sharedInstance].searchApiUrl]
                                                 parameters: parameters
                            ];
        };
        
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }
            
            // Check for error.
            if(([[weakSelf.jsonRetrieved class] isSubclassOfClass:[NSDictionary class]]) && weakSelf.jsonRetrieved[@"error"]){
                NSMutableDictionary *errorDict = [weakSelf.jsonRetrieved[@"error"] mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Page History Op" code:001 userInfo:errorDict];
            }
            
            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            NSMutableArray *output = @[].mutableCopy;

            NSMutableDictionary *parentSizes = @{}.mutableCopy;
            NSMutableDictionary *revisionsByDay = @{}.mutableCopy;
            
            NSDictionary *jsonDict = (NSDictionary *)weakSelf.jsonRetrieved;

            if (jsonDict.count > 0) {
                NSDictionary *pages = jsonDict[@"query"][@"pages"];
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
                    
                    [weakSelf calculateCharacterDeltasForRevisions:revisionsByDaySorted fromParentSizes:parentSizes];
                    
                    output = revisionsByDaySorted;
                }
            }

            completionBlock(output);
        };
    }
    return self;
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

@end
