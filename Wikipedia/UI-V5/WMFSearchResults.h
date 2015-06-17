
#import <Mantle/Mantle.h>
#import "WMFArticleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults : MTLModel<WMFArticleListDataSource>

@property (nonatomic, copy, readonly) NSString* searchTerm;
@property (nonatomic, strong, nullable, readonly) NSArray* resultArticles;
@property (nonatomic, copy, nullable, readonly) NSString* searchSuggestion;

- (instancetype)initWithSearchTerm:(NSString*)searchTerm articles:(nullable NSArray*)articles searchSuggestion:(nullable NSString*)suggestion;

- (BOOL)noResults;

@end

NS_ASSUME_NONNULL_END