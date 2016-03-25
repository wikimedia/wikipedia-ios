//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "QueuesSingleton.h"
#import "WikipediaAppUtils.h"
#import "ReadingActionFunnel.h"
#import "SessionSingleton.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "MWKLanguageLinkResponseSerializer.h"
#import <BlocksKit/BlocksKit.h>

@implementation QueuesSingleton


+ (QueuesSingleton*)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (void)reset {
    self.loginFetchManager              = [AFHTTPSessionManager wmf_createDefaultManager];
    self.sectionWikiTextDownloadManager = [AFHTTPSessionManager wmf_createDefaultManager];
    self.sectionWikiTextUploadManager   = [AFHTTPSessionManager wmf_createDefaultManager];
    self.sectionPreviewHtmlFetchManager = [AFHTTPSessionManager wmf_createDefaultManager];
    self.languageLinksFetcher           = [AFHTTPSessionManager wmf_createDefaultManager];
    self.zeroRatedMessageFetchManager   = [AFHTTPSessionManager wmf_createDefaultManager];
    self.accountCreationFetchManager    = [AFHTTPSessionManager wmf_createDefaultManager];
    self.pageHistoryFetchManager        = [AFHTTPSessionManager wmf_createDefaultManager];

    self.assetsFetchManager        = [AFHTTPSessionManager wmf_createDefaultManager];
    self.nearbyFetchManager        = [AFHTTPSessionManager wmf_createDefaultManager];
    self.articleFetchManager       = [AFHTTPSessionManager wmf_createDefaultManager];
    self.searchResultsFetchManager = [AFHTTPSessionManager wmf_createDefaultManager];

    NSArray* fetchers = @[self.assetsFetchManager,
                          self.nearbyFetchManager,
                          self.articleFetchManager,
                          self.searchResultsFetchManager,
    ];

    [fetchers bk_each:^(AFHTTPSessionManager* manager) {
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }];

    self.languageLinksFetcher.responseSerializer = [MWKLanguageLinkResponseSerializer serializer];
}

@end
