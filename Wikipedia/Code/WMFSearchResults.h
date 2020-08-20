#import <WMF/WMFMTLModel.h>

@class MWKSearchResult, MWKSearchRedirectMapping;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults : WMFMTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *searchTerm;
@property (nonatomic, strong, nullable, readonly) NSArray<MWKSearchResult *> *results;
@property (nonatomic, strong, nullable, readonly) NSArray<MWKSearchRedirectMapping *> *redirectMappings;

@property (nonatomic, copy, nullable, readonly) NSString *searchSuggestion;

- (instancetype)initWithSearchTerm:(NSString *)searchTerm
                           results:(nullable NSArray<MWKSearchResult *> *)results
                  searchSuggestion:(nullable NSString *)suggestion
                  redirectMappings:(NSArray<MWKSearchRedirectMapping *> *)redirectMappings;

@end

NS_ASSUME_NONNULL_END
