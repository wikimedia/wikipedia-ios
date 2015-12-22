
#import "WMFArticleFetcher.h"

//Tried not to do it, but we need it for the useageReports BOOL
//Plan to refactor settings into an another object, then we can remove this.
#import "SessionSingleton.h"

//AFNetworking
#import "MWNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "WMFArticleRequestSerializer.h"
#import "WMFArticleResponseSerializer.h"

//Promises
#import "Wikipedia-Swift.h"

//Models
#import "MWKTitle.h"
#import "MWKSectionList.h"
#import "MWKSection.h"
#import "MWKArticle+HTMLImageImport.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleBaseFetcher ()

@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;
@property (nonatomic, strong) NSMapTable* operationsKeyedByTitle;
@property (nonatomic, strong) dispatch_queue_t operationsQueue;

@end

@implementation WMFArticleBaseFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationsKeyedByTitle = [NSMapTable strongToWeakObjectsMapTable];
        NSString* queueID = [NSString stringWithFormat:@"org.wikipedia.articlefetcher.accessQueue.%@", [[NSUUID UUID] UUIDString]];
        self.operationsQueue = dispatch_queue_create([queueID cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        self.operationManager = manager;
    }
    return self;
}

- (WMFArticleRequestSerializer*)requestSerializer {
    return nil;
}

#pragma mark - Fetching

- (id)serializedArticleWithTitle:(MWKTitle*)title response:(id)response {
    return response;
}

- (void)fetchArticleForPageTitle:(MWKTitle*)pageTitle
                   useDesktopURL:(BOOL)useDeskTopURL
                        progress:(WMFProgressHandler __nullable)progress
                        resolver:(PMKResolver)resolve {
    if (!pageTitle.text || !pageTitle.site.language) {
        resolve([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
    }

    [self updateRequestSerializerMCCMNCHeader];

    NSURL* url = useDeskTopURL ? [pageTitle.site apiEndpoint] : [pageTitle.site mobileApiEndpoint];

    AFHTTPRequestOperation* operation = [self.operationManager GET:url.absoluteString parameters:pageTitle success:^(AFHTTPRequestOperation* operation, id response) {
        dispatchOnBackgroundQueue(^{
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve([self serializedArticleWithTitle:pageTitle response:response]);
        });
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        if ([url isEqual:[pageTitle.site mobileApiEndpoint]] && [error wmf_shouldFallbackToDesktopURLError]) {
            [self fetchArticleForPageTitle:pageTitle useDesktopURL:YES progress:progress resolver:resolve];
        } else {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            resolve(error);
        }
    }];

    __block CGFloat downloadProgress = 0.0;

    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (totalBytesExpectedToRead > 0) {
            downloadProgress = (CGFloat)(totalBytesRead / totalBytesExpectedToRead);
        } else {
            downloadProgress += 0.02;
        }

        if (downloadProgress > 1.0) {
            downloadProgress = 1.0;
        }

        if (progress) {
            progress(downloadProgress);
        }
    }];

    [self trackOperation:operation forTitle:pageTitle];
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

#pragma mark - Operation Tracking / Cancelling

- (AFHTTPRequestOperation*)trackedOperationForTitle:(MWKTitle*)title {
    if ([title.text length] == 0) {
        return nil;
    }

    __block AFHTTPRequestOperation* op = nil;

    dispatch_sync(self.operationsQueue, ^{
        op = [self.operationsKeyedByTitle objectForKey:title.text];
    });

    return op;
}

- (void)trackOperation:(AFHTTPRequestOperation*)operation forTitle:(MWKTitle*)title {
    if ([title.text length] == 0) {
        return;
    }

    dispatch_sync(self.operationsQueue, ^{
        [self.operationsKeyedByTitle setObject:operation forKey:title];
    });
}

- (BOOL)isFetchingArticleForTitle:(MWKTitle*)pageTitle {
    return [self trackedOperationForTitle:pageTitle] != nil;
}

- (void)cancelFetchForPageTitle:(MWKTitle*)pageTitle {
    if ([pageTitle.text length] == 0) {
        return;
    }

    __block AFHTTPRequestOperation* op = nil;

    dispatch_sync(self.operationsQueue, ^{
        op = [self.operationsKeyedByTitle objectForKey:pageTitle];
    });

    [op cancel];
}

- (void)cancelAllFetches {
    [self.operationManager.operationQueue cancelAllOperations];
}

#pragma mark - MCCMNC Header

- (void)updateRequestSerializerMCCMNCHeader {
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        [self requestSerializer].shouldSendMCCMNCheader = YES;
    } else {
        [self requestSerializer].shouldSendMCCMNCheader = NO;
    }
}

@end

@interface WMFArticleFetcher ()

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

@end

@implementation WMFArticleFetcher

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.operationManager.requestSerializer  = [WMFArticleRequestSerializer serializer];
        self.operationManager.responseSerializer = [WMFArticleResponseSerializer serializer];
        self.dataStore                           = dataStore;
    }
    return self;
}

- (id)serializedArticleWithTitle:(MWKTitle*)title response:(NSDictionary*)response {
    MWKArticle* article = [[MWKArticle alloc] initWithTitle:title dataStore:self.dataStore];
    @try {
        [article importMobileViewJSON:response];
        [article importAndSaveImagesFromSectionHTML];
        [article save];
        return article;
    } @catch (NSException* e) {
        DDLogError(@"Failed to import article data. Response: %@. Error: %@", response, e);
        return [NSError wmf_serializeArticleErrorWithReason:[e reason]];
    }
}

- (AnyPromise*)fetchArticleForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler __nullable)progress {
    NSAssert(pageTitle.text != nil, @"Title text nil");
    NSAssert(self.dataStore != nil, @"Store nil");
    NSAssert(self.operationManager != nil, @"Manager nil");

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self fetchArticleForPageTitle:pageTitle useDesktopURL:NO progress:progress resolver:resolve];
    }];
}

@end


NS_ASSUME_NONNULL_END