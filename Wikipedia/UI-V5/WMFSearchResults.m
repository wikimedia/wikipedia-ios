
#import "WMFSearchResults.h"
#import "WMFArticleListCell.h"
#import "MWKArticle.h"
#import "MWKTitle.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKSearchResult.h"
#import "MWKSearchRedirectMapping.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults ()
{
    NSMutableArray<MWKSearchResult*>* _mutableResults;
}

@property (nonatomic, copy, readwrite) NSString* searchTerm;
@property (nonatomic, copy, nullable, readwrite) NSString* searchSuggestion;
@property (nonatomic, strong, readwrite) NSArray<MWKSearchResult*>* results;

@end

@implementation WMFSearchResults

- (instancetype)initWithSearchTerm:(NSString*)searchTerm
                           results:(nullable NSArray*)results
                  searchSuggestion:(nullable NSString*)suggestion {
    self = [super init];
    if (self) {
        self.searchTerm       = searchTerm;
        self.results          = results;
        self.searchSuggestion = suggestion;
    }
    return self;
}

- (void)setResults:(NSArray<MWKSearchResult*>* _Nonnull)results {
    if (_mutableResults == results) {
        return;
    }
    _mutableResults = [results mutableCopy];
}

- (NSArray*)results {
    return _mutableResults;
}

+ (NSValueTransformer*)resultsJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id (NSDictionary* value, BOOL* success, NSError* __autoreleasing* error) {
        NSArray* pages = [value allValues];
        NSValueTransformer* transformer = [MTLJSONAdapter arrayTransformerWithModelClass:[MWKSearchResult class]];
        return [[transformer transformedValue:pages] sortedArrayUsingDescriptors:@[[self indexSortDescriptor]]];
    }];
}

+ (NSValueTransformer*)redirectMappingsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[MWKSearchRedirectMapping class]];
}

+ (NSSortDescriptor*)indexSortDescriptor {
    static NSSortDescriptor* indexSortDescriptor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indexSortDescriptor = [[NSSortDescriptor alloc] initWithKey:WMF_SAFE_KEYPATH(MWKSearchResult.new, index) ascending:YES];
    });
    return indexSortDescriptor;
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{
               WMF_SAFE_KEYPATH(WMFSearchResults.new, results): @"pages",
               WMF_SAFE_KEYPATH(WMFSearchResults.new, redirectMappings): @"redirects",
               WMF_SAFE_KEYPATH(WMFSearchResults.new, searchSuggestion): @"searchinfo.suggestion",
    };
}

- (void)mergeResultsFromModel:(WMFSearchResults*)searchResults {
    NSArray* newResults = [searchResults.results bk_reject:^BOOL (MWKSearchResult* obj) {
        return [self.results containsObject:obj];
    }];

    [_mutableResults addObjectsFromArray:newResults];
}

- (void)mergeSearchSuggestionFromModel:(WMFSearchResults*)searchResults {
    // preserve current search suggestion if there is one
    self.searchSuggestion = searchResults.searchSuggestion.length ? searchResults.searchSuggestion : self.searchSuggestion;
}

@end

NS_ASSUME_NONNULL_END
