//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "QueuesSingleton.h"
#import "WikipediaAppUtils.h"
#import "ReadingActionFunnel.h"
#import "SessionSingleton.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
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
    self.loginFetchManager              = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.savedPagesFetchManager         = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.sectionWikiTextDownloadManager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.sectionWikiTextUploadManager   = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.sectionPreviewHtmlFetchManager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.languageLinksFetcher           = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.zeroRatedMessageFetchManager   = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.accountCreationFetchManager    = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.pageHistoryFetchManager        = [AFHTTPRequestOperationManager wmf_createDefaultManager];

    self.assetsFetchManager        = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.nearbyFetchManager        = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.articleFetchManager       = [AFHTTPRequestOperationManager wmf_createDefaultManager];
    self.searchResultsFetchManager = [AFHTTPRequestOperationManager wmf_createDefaultManager];

    NSArray* fetchers = @[self.assetsFetchManager,
                          self.nearbyFetchManager,
                          self.articleFetchManager,
                          self.searchResultsFetchManager,
                          self.savedPagesFetchManager
    ];

    [fetchers bk_each:^(AFHTTPRequestOperationManager* manager) {
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }];
}

@end
