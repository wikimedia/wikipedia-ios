#import "WMFSearchResults_Internal.h"
#import "MWKSearchRedirectMapping.h"
@import WMF;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults () {
    NSMutableArray<MWKSearchResult *> *_mutableResults;
}

@property (nonatomic, copy, readwrite) NSString *searchTerm;
@property (nonatomic, copy, nullable, readwrite) NSString *searchSuggestion;
@property (nonatomic, strong, nullable, readwrite) NSArray<MWKSearchResult *> *results;

@end

@implementation WMFSearchResults

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableResults = [NSMutableArray new];
        _redirectMappings = @[];
    }
    return self;
}

- (instancetype)initWithSearchTerm:(NSString *)searchTerm
                           results:(nullable NSArray<MWKSearchResult *> *)results
                  searchSuggestion:(nullable NSString *)suggestion
                  redirectMappings:(NSArray<MWKSearchRedirectMapping *> *)redirectMappings {
    self = [self init];
    if (self) {
        self.searchTerm = searchTerm;
        self.results = results;
        self.searchSuggestion = suggestion;
        self.redirectMappings = redirectMappings;
    }
    return self;
}

- (void)setResults:(nullable NSArray<MWKSearchResult *> *)results {
    if (results) {
        [_mutableResults setArray:results];
    } else {
        [_mutableResults removeAllObjects];
    }
}

- (void)setRedirectMappings:(nullable NSArray<MWKSearchRedirectMapping *> *)redirectMappings {
    _redirectMappings = [redirectMappings copy] ?: @[];
}

- (nullable NSArray *)results {
    return _mutableResults;
}

+ (NSValueTransformer *)resultsJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSDictionary *value, BOOL *success, NSError *__autoreleasing *error) {
        NSArray *pages = [value allValues];
        NSValueTransformer *transformer = [MTLJSONAdapter arrayTransformerWithModelClass:[MWKSearchResult class]];
        return [[transformer transformedValue:pages] sortedArrayUsingDescriptors:@[[self indexSortDescriptor]]];
    }];
}

+ (NSValueTransformer *)redirectMappingsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[MWKSearchRedirectMapping class]];
}

+ (NSSortDescriptor *)indexSortDescriptor {
    static NSSortDescriptor *indexSortDescriptor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indexSortDescriptor = [[NSSortDescriptor alloc] initWithKey:WMF_SAFE_KEYPATH(MWKSearchResult.new, index) ascending:YES];
    });
    return indexSortDescriptor;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        WMF_SAFE_KEYPATH(WMFSearchResults.new, results): @"pages",
        WMF_SAFE_KEYPATH(WMFSearchResults.new, redirectMappings): @"redirects",
        WMF_SAFE_KEYPATH(WMFSearchResults.new, searchSuggestion): @"searchinfo.suggestion",
    };
}

#pragma mark - Merge

- (void)mergeRedirectMappingsFromModel:(WMFSearchResults *)searchResults {
    NSArray *newMappings = [searchResults.redirectMappings wmf_reject:^BOOL(MWKSearchRedirectMapping *mapping) {
        return [self.redirectMappings containsObject:mapping];
    }];
    self.redirectMappings = [self.redirectMappings arrayByAddingObjectsFromArray:newMappings];
}

- (void)mergeResultsFromModel:(WMFSearchResults *)searchResults {
    NSMutableSet *displayTitlesOfExistingResults = [NSMutableSet new];
    for (MWKSearchResult *obj in self.results) {
        if (obj.displayTitle) {
            [displayTitlesOfExistingResults addObject:obj.displayTitle];
        }
    }

    NSArray *newResults = [searchResults.results wmf_reject:^BOOL(MWKSearchResult *obj) {
        if (obj.displayTitle) {
            return [displayTitlesOfExistingResults containsObject:obj.displayTitle];
        }
        return YES;
    }];
    [self.mutableResults addObjectsFromArray:newResults];
}

- (void)mergeSearchSuggestionFromModel:(WMFSearchResults *)searchResults {
    // preserve current search suggestion if there is one
    if (self.searchSuggestion.length) {
        return;
    }
    self.searchSuggestion = searchResults.searchSuggestion;
}

#pragma mark - KVO

- (NSMutableArray *)mutableResults {
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

- (void)insertResults:(NSArray *)entrieArray atIndexes:(NSIndexSet *)indexes {
    [_mutableResults insertObjects:entrieArray atIndexes:indexes];
}

- (void)removeObjectFromResultsAtIndex:(NSUInteger)idx {
    [_mutableResults removeObjectAtIndex:idx];
}

- (void)removeResultsAtIndexes:(NSIndexSet *)indexes {
    [_mutableResults removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInResultsAtIndex:(NSUInteger)idx withObject:(id)anObject {
    [_mutableResults replaceObjectAtIndex:idx withObject:anObject];
}

- (void)replaceResultsAtIndexes:(NSIndexSet *)indexes withResults:(NSArray *)entrieArray {
    [_mutableResults replaceObjectsAtIndexes:indexes withObjects:entrieArray];
}

#pragma mark - Propagate Language Variant Code

+ (NSArray<NSString *> *)languageVariantCodePropagationSubelementKeys {
    return @[@"results", @"redirectMappings"];
}

// No languageVariantCodePropagationURLKeys

@end

NS_ASSUME_NONNULL_END
