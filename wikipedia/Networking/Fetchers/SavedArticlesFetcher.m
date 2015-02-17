
#import "SavedArticlesFetcher.h"
#import "ArticleFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import <BlocksKit/BlocksKit.h>

@interface SavedArticlesFetcher()<FetchFinishedDelegate>

@property (nonatomic, strong, readwrite) MWKSavedPageList *savedPageList;
@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;

@property (nonatomic, strong) NSMutableDictionary *fetchersByArticleTitle;
@property (nonatomic, strong) NSMutableDictionary *errorsByArticleTitle;

@property (nonatomic, strong) NSMutableArray *fetchedArticles;

@property (nonatomic, strong) dispatch_queue_t accessQueue;

@end

@implementation SavedArticlesFetcher

#pragma mark - Shared Access

static SavedArticlesFetcher* _fetcher = nil;

+ (SavedArticlesFetcher*)sharedInstance{
    
    return _fetcher;
}

+ (void)setSharedInstance:(SavedArticlesFetcher*)fetcher{
    
    _fetcher = fetcher;
}


- (instancetype)initAndFetchArticlesForSavedPageList: (MWKSavedPageList *)savedPageList
                                         inDataStore: (MWKDataStore *)dataStore
                                         withManager: (AFHTTPRequestOperationManager *)manager
                                  thenNotifyDelegate: (id <SavedArticlesFetcherDelegate>) delegate{
    
    self = [super init];
    assert(savedPageList != nil);
    assert(dataStore != nil);
    assert(manager != nil);
    assert(delegate != nil);
    if (self) {
        self.accessQueue = dispatch_queue_create("org.wikipedia.savedarticlesfetcher.accessQueue", DISPATCH_QUEUE_SERIAL);
        self.savedPageList = savedPageList;
        self.dataStore = dataStore;
        self.fetchFinishedDelegate = delegate;
        [self fetchWithManager:manager];
    }
    return self;
    
}


- (void)fetchWithManager:(AFHTTPRequestOperationManager *)manager{
    
    dispatch_async(self.accessQueue, ^{
        
        [manager.operationQueue cancelAllOperations];
        
        self.fetchersByArticleTitle = [NSMutableDictionary dictionary];
        self.errorsByArticleTitle = [NSMutableDictionary dictionary];
        self.fetchedArticles = [NSMutableArray array];
        
        for (MWKSavedPageEntry* entry in self.savedPageList) {
            
            MWKArticle *article = [self.dataStore articleWithTitle:entry.title];
            article.needsRefresh = NO;
            
            if(entry.title)
                self.fetchersByArticleTitle[entry.title] = [[ArticleFetcher alloc] initAndFetchSectionsForArticle:article withManager:manager thenNotifyDelegate:self];
            
        }
    });
    
}

- (void)fetchFinished:(id)sender fetchedData:(id)fetchedData status:(FetchFinalStatus)status error:(NSError *)error{
    
    dispatch_async(self.accessQueue, ^{
        
        __block id completedFetcherKey;
        
        [self.fetchersByArticleTitle enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            if([sender isEqual:obj]){
                completedFetcherKey = key;
                *stop = YES;
            }
        }];
        
        if(error){
            
            self.errorsByArticleTitle[completedFetcherKey] = error;
        }
        
        [self.fetchersByArticleTitle removeObjectForKey:completedFetcherKey];
        
        MWKArticle *article = [self.dataStore articleWithTitle:completedFetcherKey];
        
        [self.fetchedArticles addObject:article];
        
        [self.fetchFinishedDelegate savedArticlesFetcher:self didFetchArticle:article remainingArticles:[self.fetchersByArticleTitle count] totalArticles:self.savedPageList.length status:status error:error];
        
        if([self.fetchersByArticleTitle count] == 0){
            [self notifyDelegate];
        }
        
    });
    
}


- (void)notifyDelegate{
    
    NSError* reportedError;
    if([self.errorsByArticleTitle count] > 0)
        reportedError = [[self.errorsByArticleTitle allValues] firstObject];
    
    [self finishWithError: reportedError
              fetchedData: nil];

    
}




@end
