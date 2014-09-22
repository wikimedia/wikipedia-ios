//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, RandomArticleFetchErrorType) {
    RANDOM_ARTICLE_FETCH_ERROR_UNKNOWN = 0,
    RANDOM_ARTICLE_FETCH_ERROR_API = 1
};

@class AFHTTPRequestOperationManager;

@interface RandomArticleFetcher : FetcherBase

@property (strong, nonatomic, readonly) NSString *domain;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndFetchRandomArticleForDomain: (NSString *)domain
                                      withManager: (AFHTTPRequestOperationManager *)manager
                               thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
