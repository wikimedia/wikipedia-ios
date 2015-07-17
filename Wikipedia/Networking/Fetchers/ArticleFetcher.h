//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

@class AFHTTPRequestOperationManager, ArticleFetcher, AFHTTPRequestOperation, MWKTitle, MWKDataStore;

@interface ArticleFetcher : FetcherBase

- (AFHTTPRequestOperation*)fetchSectionsForTitle:(MWKTitle*)title
                                     inDataStore:(MWKDataStore*)store
                            fetchLeadSectionOnly:(BOOL)fetchLeadSectionOnly
                                     withManager:(AFHTTPRequestOperationManager*)manager
                                   progressBlock:(WMFProgressHandler)progress
                                 completionBlock:(WMFArticleHandler)completion
                                      errorBlock:(WMFErrorHandler)errorHandler;

@end
