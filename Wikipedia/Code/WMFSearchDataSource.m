#import "WMFSearchDataSource.h"
#import "WMFSearchResults.h"
#import "MWKSearchResult.h"

@interface WMFSearchDataSource ()

@property (nonatomic, strong, readwrite) NSURL *searchSiteURL;
@property (nonatomic, strong, readwrite) WMFSearchResults *searchResults;

@end

@implementation WMFSearchDataSource

- (nonnull instancetype)initWithSearchSiteURL:(NSURL *)url searchResults:(WMFSearchResults *)searchResults {
    NSParameterAssert(url);
    NSParameterAssert(searchResults);
    self = [super initWithTarget:searchResults keyPath:WMF_SAFE_KEYPATH(searchResults, results)];
    if (self) {
        self.searchSiteURL = url;
        self.searchResults = searchResults;
    }
    return self;
}

- (NSArray<NSURL *> *)urls {
    return [[self.searchResults results] wmf_map:^id(MWKSearchResult *obj) {
        return [self.searchSiteURL wmf_URLWithTitle:obj.displayTitle];
    }];
}

- (NSUInteger)titleCount {
    return [self.searchResults.results count];
}

- (MWKSearchResult *)searchResultForIndexPath:(NSIndexPath *)indexPath {
    MWKSearchResult *result = self.searchResults.results[indexPath.row];
    return result;
}

- (NSURL *)urlForIndexPath:(NSIndexPath *)indexPath {
    MWKSearchResult *result = [self searchResultForIndexPath:indexPath];
    return [self.searchSiteURL wmf_URLWithTitle:result.displayTitle];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)noResults {
    return (self.searchResults && [self.searchResults.results count] == 0);
}

@end
