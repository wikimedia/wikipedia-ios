
#import "WMFSearchResults.h"
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableResults   = [NSMutableArray new];
        _redirectMappings = @[];
    }
    return self;
}

- (instancetype)initWithSearchTerm:(NSString*)searchTerm
                           results:(nullable NSArray*)results
                  searchSuggestion:(nullable NSString*)suggestion {
    self = [self init];
    if (self) {
        self.searchTerm       = searchTerm;
        self.results          = results;
        self.searchSuggestion = suggestion;
    }
    return self;
}

- (void)setResults:(nullable NSArray<MWKSearchResult*>*)results {
    if ([_mutableResults isEqualToArray:results]) {
        return;
    }
    [self willChangeValueForKey:WMF_SAFE_KEYPATH(self, results)];
    if (results) {
        [_mutableResults setArray:results];
    } else {
        [_mutableResults removeAllObjects];
    }
    [self didChangeValueForKey:WMF_SAFE_KEYPATH(self, results)];
}

- (void)setRedirectMappings:(nullable NSArray<MWKSearchRedirectMapping*>*)redirectMappings {
    if (WMF_EQUAL(self.redirectMappings, isEqualToArray:, redirectMappings)) {
        return;
    }
    [self willChangeValueForKey:WMF_SAFE_KEYPATH(self, redirectMappings)];
    _redirectMappings = [redirectMappings copy] ? : @[];
    [self didChangeValueForKey:WMF_SAFE_KEYPATH(self, redirectMappings)];
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

    [self.mutableResults addObjectsFromArray:newResults];
}

- (void)mergeSearchSuggestionFromModel:(WMFSearchResults*)searchResults {
    // preserve current search suggestion if there is one
    self.searchSuggestion = searchResults.searchSuggestion.length ? searchResults.searchSuggestion : self.searchSuggestion;
}

#pragma mark - KVO

- (NSMutableArray*)mutableResults {
    return [self mutableArrayValueForKey:WMF_SAFE_KEYPATH(self, results)];
}

- (NSUInteger)countOfResults {
    return [_mutableResults count];
}

- (id)objectInResultsAtIndex:(NSUInteger)idx {
    return [_mutableResults objectAtIndex:idx];
}

- (void)insertObject:(id)anObject inResultsAtIndex:(NSUInteger)idx {
    [_mutableResults insertObject:anObject atIndex:idx];
}

- (void)insertResults:(NSArray*)entrieArray atIndexes:(NSIndexSet*)indexes {
    [_mutableResults insertObjects:entrieArray atIndexes:indexes];
}

- (void)removeObjectFromResultsAtIndex:(NSUInteger)idx {
    [_mutableResults removeObjectAtIndex:idx];
}

- (void)removeResultsAtIndexes:(NSIndexSet*)indexes {
    [_mutableResults removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInResultsAtIndex:(NSUInteger)idx withObject:(id)anObject {
    [_mutableResults replaceObjectAtIndex:idx withObject:anObject];
}

- (void)replaceResultsAtIndexes:(NSIndexSet*)indexes withResults:(NSArray*)entrieArray {
    [_mutableResults replaceObjectsAtIndexes:indexes withObjects:entrieArray];
}

@end

NS_ASSUME_NONNULL_END
