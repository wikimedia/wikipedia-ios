//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

@class AFHTTPRequestOperationManager;

@interface PreviewHtmlFetcher : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndFetchHtmlForWikiText: (NSString *)wikiText
                                     title: (NSString *)title
                                    domain: (NSString *)domain
                               withManager: (AFHTTPRequestOperationManager *)manager
                        thenNotifyDelegate: (id <FetchFinishedDelegate>) delegate;
@end
