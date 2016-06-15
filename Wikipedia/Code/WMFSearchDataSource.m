
#import "WMFSearchDataSource.h"
#import "MWKTitle.h"
#import "WMFSearchResults.h"
#import "MWKSearchResult.h"

@interface WMFSearchDataSource ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong, readwrite) WMFSearchResults* searchResults;

@end

@implementation WMFSearchDataSource

- (nonnull instancetype)initWithSearchSite:(MWKSite*)site searchResults:(WMFSearchResults*)searchResults {
    NSParameterAssert(site);
    NSParameterAssert(searchResults);
    self = [super initWithTarget:searchResults keyPath:WMF_SAFE_KEYPATH(searchResults, results)];
    if (self) {
        self.searchSite    = site;
        self.searchResults = searchResults;
    }
    return self;
}

- (NSArray*)titles {
    return [[self.searchResults results] bk_map:^id (MWKSearchResult* obj) {
        return [[MWKTitle alloc] initWithSite:self.searchSite normalizedTitle:obj.displayTitle fragment:nil];
    }];
}

- (NSUInteger)titleCount {
    return [self.searchResults.results count];
}

- (MWKSearchResult*)searchResultForIndexPath:(NSIndexPath*)indexPath {
    MWKSearchResult* result = self.searchResults.results[indexPath.row];
    return result;
}

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    MWKSearchResult* result = [self searchResultForIndexPath:indexPath];
    return [[MWKTitle alloc] initWithSite:self.searchSite normalizedTitle:result.displayTitle fragment:nil];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return NO;
}

- (BOOL)noResults {
    return (self.searchResults && [self.searchResults.results count] == 0);
}

@end
