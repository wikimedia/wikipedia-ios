//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, SearchResultFetcherErrorType) {
    SEARCH_RESULT_ERROR_UNKNOWN = 0,
    SEARCH_RESULT_ERROR_API = 1,
    SEARCH_RESULT_ERROR_NO_MATCHES = 2
};

@class AFHTTPRequestOperationManager;

@interface SearchResultFetcher : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndSearchForTerm: (NSString *)searchTerm
                        withManager: (AFHTTPRequestOperationManager *)manager
                 thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
