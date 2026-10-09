#import <WMF/WMFMTLModel.h>

@class MWKSearchResult, MWKSearchRedirectMapping;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults : WMFMTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *searchTerm;
@property (nonatomic, strong, nullable, readonly) NSArray<MWKSearchResult *> *results;
@property (nonatomic, strong, nullable, readonly) NSArray<MWKSearchRedirectMapping *> *redirectMappings;

@property (nonatomic, copy, nullable, readonly) NSString *searchSuggestion;

/// The id CirrusSearch gives to the prefix search request, from its `x-search-id` response header.
@property (nonatomic, copy, nullable, readonly) NSString *prefixSearchID;
/// The id CirrusSearch gives to the full text search request, when one was made.
@property (nonatomic, copy, nullable, readonly) NSString *fullTextSearchID;

- (instancetype)initWithSearchTerm:(NSString *)searchTerm
                           results:(nullable NSArray<MWKSearchResult *> *)results
                  searchSuggestion:(nullable NSString *)suggestion
                  redirectMappings:(NSArray<MWKSearchRedirectMapping *> *)redirectMappings;

@end

NS_ASSUME_NONNULL_END
