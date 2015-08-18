
#import "WMFSearchResults.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFSearchResults ()

@property (nonatomic, copy, readwrite) NSString* searchTerm;
@property (nonatomic, copy, nullable, readwrite) NSString* searchSuggestion;

@end

@implementation WMFSearchResults

- (instancetype)initWithSearchTerm:(NSString*)searchTerm articles:(nullable NSArray*)articles searchSuggestion:(nullable NSString*)suggestion {
    self = [super initWithItems:articles];
    if (self) {
        self.searchTerm       = searchTerm;
        self.searchSuggestion = suggestion;
    }
    return self;
}

- (nullable NSString*)displayTitle {
    return self.searchTerm;
}

- (NSArray*)articles {
    return [self allItems];
}

- (NSUInteger)articleCount {
    return [self.articles count];
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    return self.articles[indexPath.row];
}

- (NSIndexPath*)indexPathForArticle:(MWKArticle*)article {
    NSUInteger index = [self.articles indexOfObject:article];
    if (index == NSNotFound) {
        return nil;
    }

    return [NSIndexPath indexPathForItem:index inSection:0];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return NO;
}

- (BOOL)noResults {
    return (self.searchTerm && [self.articles count] == 0);
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodSearch;
}

@end

NS_ASSUME_NONNULL_END
