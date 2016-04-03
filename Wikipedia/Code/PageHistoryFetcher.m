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
#import "WMFPageHistoryRevision.h"
#import <Mantle/Mantle.h>
#import "WMFApiJsonResponseSerializer.h"
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "AFHTTPSessionManager+WMFConfig.h"

@interface PageHistoryFetcher ()
@property (nonatomic, strong) AFHTTPSessionManager* operationManager;
@property (nonatomic, strong) NSString* continueKey;
@property (nonatomic, strong) NSString* rvcontinueKey;
@property (nonatomic, assign, readwrite) BOOL batchComplete;
@end

@implementation PageHistoryFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager* manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFApiJsonResponseSerializer serializer];
        self.operationManager      = manager;
    }
    return self;
}

- (AnyPromise*)fetchRevisionInfoForTitle:(MWKTitle*)title {
    NSParameterAssert(title);
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        
        [self.operationManager wmf_GETWithSite:title.site
                                    parameters:[self getParamsForTitle:title]
                                         retry:NULL
                                       success:^(NSURLSessionDataTask* operation, id responseObject) {
                                           NSDictionary *continueInfo = responseObject[@"continue"];
                                           if (continueInfo) {
                                               self.continueKey = continueInfo[@"continue"];
                                               self.rvcontinueKey = continueInfo[@"rvcontinue"];
                                           }
                                           
                                           if (responseObject[@"batchcomplete"]) {
                                               self.batchComplete = YES;
                                           }
                                               [[MWNetworkActivityIndicatorManager sharedManager] pop];
                                           resolve([self getSanitizedResponse:responseObject]);
                                       }
                                       failure:^(NSURLSessionDataTask* operation, NSError* error) {
                                           [[MWNetworkActivityIndicatorManager sharedManager] pop];
                                           resolve(error);
                                       }];
    }];
}

- (NSDictionary*)getParamsForTitle:(MWKTitle*)title {
    NSMutableDictionary *params = @{
        @"action": @"query",
        @"prop": @"revisions",
        @"rvprop": @"ids|timestamp|user|size|parsedcomment",
        @"rvlimit": @51,
        @"rvdir": @"older",
        @"titles": title.text,
        @"continue": self.continueKey ?: @"",
        @"format": @"json"
        //,@"rvdiffto": @(-1) // Add this to fake out "error" api response.
    }.mutableCopy;
    
    if (self.rvcontinueKey) {
        params[@"rvcontinue"] = self.rvcontinueKey;
    }
    
    return params;
}

- (NSArray*)getSanitizedResponse:(NSDictionary*)rawResponse {
    NSMutableDictionary<NSNumber *, NSMutableArray<WMFPageHistoryRevision*>*>* revisionsByDay = @{}.mutableCopy;

    if (rawResponse.count > 0) {
        NSDictionary* pages = rawResponse[@"query"][@"pages"];
        if (pages) {
            for (NSDictionary* page in pages) {
                NSArray<WMFPageHistoryRevision*>* revisions = [[MTLJSONAdapter arrayTransformerWithModelClass:[WMFPageHistoryRevision class]] transformedValue:pages[page][@"revisions"]];
                
                WMFPageHistoryRevision* earliestRevision = revisions.lastObject;
                if (earliestRevision.parentID == 0) {
                    earliestRevision.revisionSize = earliestRevision.articleSizeAtRevision;
                    [self updateRevisionsByDay:revisionsByDay withRevision:earliestRevision];
                }
                
                for (NSInteger i = revisions.count - 2; i >= 0; i--) {
                    WMFPageHistoryRevision* previous = revisions[i + 1];
                    WMFPageHistoryRevision* current = revisions[i];
                    current.revisionSize = current.articleSizeAtRevision - previous.articleSizeAtRevision;
                    [self updateRevisionsByDay:revisionsByDay withRevision:current];
                }
            }
        }
    }
    
    NSArray * sortedKeys = [[revisionsByDay allKeys] sortedArrayUsingSelector: @selector(compare:)];
    NSArray<NSMutableArray<WMFPageHistoryRevision*>*>* objects = [revisionsByDay objectsForKeys: sortedKeys notFoundMarker: @[].mutableCopy];
    
    return objects;
}

- (void)updateRevisionsByDay:(NSMutableDictionary<NSNumber *, NSMutableArray<WMFPageHistoryRevision*>*>*)revisionsByDay withRevision:(WMFPageHistoryRevision*)revision {
    NSInteger distanceInDaysToDate = [revision daysFromToday];
    if (!revisionsByDay[@(distanceInDaysToDate)]) {
        revisionsByDay[@(distanceInDaysToDate)] = @[].mutableCopy;
    }
    
    NSMutableArray<WMFPageHistoryRevision*>* revisionRowArray = revisionsByDay[@(distanceInDaysToDate)];
    [revisionRowArray insertObject:revision atIndex:0];
}

@end
