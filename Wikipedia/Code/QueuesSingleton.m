#import "QueuesSingleton.h"
#import "AFHTTPSessionManager+WMFConfig.h"
#import "MWKLanguageLinkResponseSerializer.h"

@implementation QueuesSingleton

+ (QueuesSingleton *)sharedInstance {
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
    self.sectionWikiTextDownloadManager = [AFHTTPSessionManager wmf_createDefaultManager];
    self.sectionWikiTextUploadManager = [AFHTTPSessionManager wmf_createDefaultManager];
    self.sectionPreviewHtmlFetchManager = [AFHTTPSessionManager wmf_createDefaultManager];
    self.languageLinksFetcher = [AFHTTPSessionManager wmf_createDefaultManager];

    self.assetsFetchManager = [AFHTTPSessionManager wmf_createDefaultManager];

    self.assetsFetchManager.responseSerializer = [AFHTTPResponseSerializer serializer];

    self.languageLinksFetcher.responseSerializer = [MWKLanguageLinkResponseSerializer serializer];
}

@end
