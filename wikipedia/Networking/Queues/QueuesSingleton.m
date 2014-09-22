//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "QueuesSingleton.h"
#import "WikipediaAppUtils.h"

@implementation QueuesSingleton

+ (QueuesSingleton *)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {

        [self setupManagers];

        [self setRequestHeadersForManagers:@[
            self.loginFetchManager,
            self.articleFetchManager,
            self.savedPagesFetchManager,
            self.searchResultsFetchManager,
            self.sectionWikiTextDownloadManager,
            self.sectionWikiTextUploadManager,
            self.sectionPreviewHtmlFetchManager,
            self.languageLinksFetcher,
            self.zeroRatedMessageFetchManager,
            self.accountCreationFetchManager,
            self.pageHistoryFetchManager,
            self.assetsFetchManager,
            self.nearbyFetchManager
        ]];

        [self setDefaultSerializerForManagers:@[
            self.nearbyFetchManager,
            self.searchResultsFetchManager,
            self.assetsFetchManager
        ]];

        //[self setupQMonitorLogging];
    }
    return self;
}

-(void)setupManagers
{
    self.loginFetchManager = [AFHTTPRequestOperationManager manager];
    self.articleFetchManager = [AFHTTPRequestOperationManager manager];
    self.savedPagesFetchManager = [AFHTTPRequestOperationManager manager];
    self.searchResultsFetchManager = [AFHTTPRequestOperationManager manager];
    self.sectionWikiTextDownloadManager = [AFHTTPRequestOperationManager manager];
    self.sectionWikiTextUploadManager = [AFHTTPRequestOperationManager manager];
    self.sectionPreviewHtmlFetchManager = [AFHTTPRequestOperationManager manager];
    self.languageLinksFetcher = [AFHTTPRequestOperationManager manager];
    self.zeroRatedMessageFetchManager = [AFHTTPRequestOperationManager manager];
    self.accountCreationFetchManager = [AFHTTPRequestOperationManager manager];
    self.pageHistoryFetchManager = [AFHTTPRequestOperationManager manager];
    self.assetsFetchManager = [AFHTTPRequestOperationManager manager];
    self.nearbyFetchManager = [AFHTTPRequestOperationManager manager];
}

-(void)setRequestHeadersForManagers:(NSArray *)managers
{
    for (AFHTTPRequestOperationManager *manager in managers.copy) {
        [self setRequestHeadersForManager:manager];
    }
}

-(void)setDefaultSerializerForManagers:(NSArray *)managers
{
    // Set the responseSerializer to AFHTTPResponseSerializer, so that it will no longer
    // try to parse the JSON - needed because we use some managers to fetch different
    // content types, say, both nearby json api data *and* thumbnails. Thumb responses
    // are not json! And some managers, like the assetsFetchManager don't retrieve json
    // at all.
    // From: http://stackoverflow.com/a/21621530
    for (AFHTTPRequestOperationManager *manager in managers.copy) {
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
}

-(void)setRequestHeadersForManager:(AFHTTPRequestOperationManager *)manager
{
    [manager.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [manager.requestSerializer setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];

    // x-www-form-urlencoded is default, so probably don't need it.
    // See: http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1
    //[manager.requestSerializer setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
}

-(void)setupQMonitorLogging
{
    // Listen in on the Q's op counts to ensure they go away properly.
    [self.articleFetchManager.operationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    [self.searchResultsFetchManager.operationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"operationCount"]) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"QUEUE OP COUNTS: Search %lu, Article %lu",
                (unsigned long)self.searchResultsFetchManager.operationQueue.operationCount,
                (unsigned long)self.articleFetchManager.operationQueue.operationCount
            );
        });
    }
}

@end
