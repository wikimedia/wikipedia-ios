
@import Foundation;
#import <Mantle/Mantle.h>

@class MWKSearchResult;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString* searchTerm;
@property (nonatomic, strong, readonly) NSArray<MWKSearchResult*>* results;
@property (nonatomic, copy, nullable, readonly) NSString* searchSuggestion;

- (instancetype)initWithSearchTerm:(NSString*)searchTerm
                           results:(nullable NSArray*)results
                  searchSuggestion:(nullable NSString*)suggestion;
@end

NS_ASSUME_NONNULL_END