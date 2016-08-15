#import "WMFNearbyTitleListDataSource.h"
#import "WMFLocationSearchFetcher.h"

// Models
#import "MWKSavedPageList.h"
#import "MWKLocationSearchResult.h"
#import "MWKArticle.h"
#import "WMFLocationSearchResults.h"
#import "MWKHistoryEntry.h"

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const WMFNearbyDataSourceFetchCount = 20;

@interface WMFNearbyTitleListDataSource ()

@property(nonatomic, strong, readwrite) NSURL *searchSiteURL;
@property(nonatomic, strong) WMFLocationSearchFetcher *locationSearchFetcher;
@property(nonatomic, strong, nullable) WMFLocationSearchResults *searchResults;
@property(nonatomic, strong) MWKSavedPageList *savedPageList;

@property(nonatomic, weak) id<Cancellable> lastFetch;

@end

@implementation WMFNearbyTitleListDataSource

- (instancetype)initWithSearchSiteURL:(NSURL *)url {
  NSParameterAssert(url);
  self = [super initWithItems:nil];
  if (self) {
    self.searchSiteURL = url;
    self.locationSearchFetcher = [[WMFLocationSearchFetcher alloc] init];
  }
  return self;
}

- (void)setLocation:(CLLocation *)location {
  if (WMF_IS_EQUAL(_location, location)) {
    return;
  }
  _location = location;
  [self fetchDataIfNeeded];
}

#pragma mark - WMFTitleListDataSource

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath *__nonnull)indexPath {
  return NO;
}

- (NSArray<NSURL *> *)urls {
  return [self.searchResults.results bk_map:^id(MWKLocationSearchResult *obj) {
    return [self.searchSiteURL wmf_URLWithTitle:obj.displayTitle];
  }];
}

- (NSUInteger)titleCount {
  return self.searchResults.results.count;
}

- (MWKLocationSearchResult *)searchResultForIndexPath:(NSIndexPath *)indexPath {
  MWKLocationSearchResult *result = self.searchResults.results[indexPath.row];
  return result;
}

- (NSURL *)urlForIndexPath:(NSIndexPath *)indexPath {
  MWKLocationSearchResult *result = [self searchResultForIndexPath:indexPath];
  return [self.searchSiteURL wmf_URLWithTitle:result.displayTitle];
}

#pragma mark - Fetch

- (BOOL)fetchedResultsAreCloseToLocation:(CLLocation *)location {
  if ([self.searchResults.location distanceFromLocation:location]<
          500 &&
          [self.searchResults.searchSiteURL isEqual:self.searchSiteURL] &&
          [self.searchResults.results count]> 0) {
    return YES;
  }

  return NO;
}

- (void)fetchDataIfNeeded {
  if (!self.location) {
    return;
  }

  if ([self fetchedResultsAreCloseToLocation:self.location]) {
    DDLogVerbose(@"Not fetching nearby titles for %@ since it is too close to "
                 @"previously fetched location: %@.",
                 self.location, self.searchResults.location);
    return;
  }

  [self fetchTitlesForLocation:self.location];
}

- (void)fetchTitlesForLocation:(CLLocation *__nullable)location {
  [self.lastFetch cancel];
  id<Cancellable> fetch;
  @weakify(self);
  [self.locationSearchFetcher
      fetchArticlesWithSiteURL:self.searchSiteURL
                      location:location
                   resultLimit:WMFNearbyDataSourceFetchCount
                   cancellable:&fetch]
      .then(^(WMFLocationSearchResults *locationSearchResults) {
        @strongify(self);
        self.searchResults = locationSearchResults;
        [self updateItems:locationSearchResults.results];
      })
      .catch(^(NSError *error) {
        // This means there were 0 results - not neccesarily a "real" error.
        // Only inform the delegate if we get a real error.
        if (!([error.domain isEqualToString:MTLJSONAdapterErrorDomain] &&
              error.code == MTLJSONAdapterErrorInvalidJSONDictionary)) {
          // TODO: propagate error to view controller
        }
      });
  self.lastFetch = fetch;
}

@end

NS_ASSUME_NONNULL_END
