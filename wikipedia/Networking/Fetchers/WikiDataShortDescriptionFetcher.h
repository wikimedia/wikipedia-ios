//  Created by Monte Hurd on 11/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"
#import "Defines.h"

typedef NS_ENUM(NSInteger, WikiDataShortDescriptionFetcherErrorType) {
    SHORT_DESCRIPTION_ERROR_UNKNOWN = 0,
    SHORT_DESCRIPTION_ERROR_API = 1,
    SHORT_DESCRIPTION_ERROR_NO_MATCHES = 2
};

@class AFHTTPRequestOperationManager;

@interface WikiDataShortDescriptionFetcher : FetcherBase

@property (nonatomic, strong, readonly) NSArray *wikiDataIds;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndFetchDescriptionsForIds: (NSArray *)wikiDataIds
                                  withManager: (AFHTTPRequestOperationManager *)manager
                           thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
