//  Created by Monte Hurd on 11/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"
#import "Defines.h"
#import "SearchResultFetcher.h"

typedef NS_ENUM(NSInteger, WikiDataShortDescriptionFetcherErrorType) {
    SHORT_DESCRIPTION_ERROR_UNKNOWN = 0,
    SHORT_DESCRIPTION_ERROR_API,
    SHORT_DESCRIPTION_ERROR_NO_MATCHES
};

@class AFHTTPRequestOperationManager;

@interface WikiDataShortDescriptionFetcher : FetcherBase

@property (nonatomic, strong, readonly) NSArray *wikiDataIds;
@property (nonatomic, readonly) SearchType searchType;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndFetchDescriptionsForIds: (NSArray *)wikiDataIds
                                   searchType: (SearchType)searchType
                                  withManager: (AFHTTPRequestOperationManager *)manager
                           thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
