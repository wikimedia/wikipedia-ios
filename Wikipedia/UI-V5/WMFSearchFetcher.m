
#import "WMFSearchFetcher.h"
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "SearchResultFetcher.h"
#import "WMFSearchResults.h"

NSUInteger const kWMFmaxSearchResults = 24;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchFetcher ()<FetchFinishedDelegate>

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

@property (nonatomic, strong) AFHTTPRequestOperationManager* operationManager;

@property (nonatomic, strong) SearchResultFetcher* fetcher;

@property (nonatomic, strong, nullable) AFHTTPRequestOperation* operation;
@property (nonatomic, copy, nullable) PMKResolver resolver;

@property (nonatomic, strong, nullable) WMFSearchResults* previousResults;

@end

@implementation WMFSearchFetcher

- (instancetype)initWithSearchSite:(MWKSite*)site dataStore:(MWKDataStore*)dataStore{

    self = [super init];
    if (self) {
        self.searchSite = site;
        self.dataStore = dataStore;
        self.maxSearchResults = kWMFmaxSearchResults;
        AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        self.operationManager = manager;
    }
    return self;
}

- (AnyPromise*)searchArticleTitlesForSearchTerm:(NSString*)searchTerm searchType:(SearchType)type{
    
    [self.operation cancel];
    
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        
        self.resolver = resolve;
        
        self.fetcher = [[SearchResultFetcher alloc] init];
        self.operation = [self.fetcher searchForTerm:searchTerm searchType:type searchReason:SEARCH_REASON_UNKNOWN language:self.searchSite.language maxResults:self.maxSearchResults withManager:self.operationManager thenNotifyDelegate:self];
    }];
}

- (AnyPromise*)searchArticleTitlesForSearchTerm:(NSString*)searchTerm{
    
    return [self searchArticleTitlesForSearchTerm:searchTerm searchType:SEARCH_TYPE_TITLES];
}


- (AnyPromise*)searchFullArticleTextForSearchTerm:(NSString*)searchTerm appendToPreviousResults:(WMFSearchResults*)results{
    
    self.previousResults = results;
    return [self searchArticleTitlesForSearchTerm:searchTerm searchType:SEARCH_TYPE_IN_ARTICLES];
}

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error{
    
    if(self.resolver){

        if(!error){
            self.resolver([self searchResultsFromFetcher:sender]);
        }else{
            self.resolver(error);
        }
        self.operation = nil;
        self.resolver = nil;
    }
}

- (WMFSearchResults*)searchResultsFromFetcher:(SearchResultFetcher*)resultsFetcher{
    
    NSArray* articles = [resultsFetcher.searchResults bk_map:^id(NSDictionary* obj) {
        
        MWKTitle* title = [MWKTitle titleWithString:obj[@"title"] site:self.searchSite];
        MWKArticle* article = [[MWKArticle alloc] initWithTitle:title dataStore:self.dataStore searchResultsDict:obj];
        article.thumbnailURL = resultsFetcher.articleTitleToImageMap[title.text];
        [article loadThumbnailFromDisk];
        
        return article;
    }];
    
    WMFSearchResults* results = [[WMFSearchResults alloc] initWithSearchTerm:resultsFetcher.searchTerm articles:articles searchSuggestion:resultsFetcher.searchSuggestion];

    return results;
}



@end

NS_ASSUME_NONNULL_END