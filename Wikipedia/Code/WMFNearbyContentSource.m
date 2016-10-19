#import "WMFNearbyContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "WMFArticlePreviewDataStore.h"

#import "WMFContentGroup+WMFDatabaseStorable.h"
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"
#import "CLLocation+WMFComparison.h"

@import NSDate_Extensions;
@import YapDatabase;

@interface WMFNearbyContentSource () <WMFLocationManagerDelegate>

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@property (nonatomic, strong, readwrite) WMFLocationManager *currentLocationManager;
@property (nonatomic, strong) WMFLocationSearchFetcher *locationSearchFetcher;

@property (readwrite, nonatomic, assign) BOOL isFetchingInitialLocation;

@property (readwrite, nonatomic, assign) BOOL isProcessingLocation;

@property (readwrite, nonatomic, copy) dispatch_block_t completion;

@end

@implementation WMFNearbyContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore {
    NSParameterAssert(siteURL);
    NSParameterAssert(contentStore);
    NSParameterAssert(previewStore);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.contentStore = contentStore;
        self.previewStore = previewStore;
    }
    return self;
}

- (WMFLocationManager *)currentLocationManager {
    if (_currentLocationManager == nil) {
        _currentLocationManager = [WMFLocationManager coarseLocationManager];
        _currentLocationManager.delegate = self;
    }
    return _currentLocationManager;
}

- (WMFLocationSearchFetcher *)locationSearchFetcher {
    if (_locationSearchFetcher == nil) {
        _locationSearchFetcher = [[WMFLocationSearchFetcher alloc] init];
    }
    return _locationSearchFetcher;
}

#pragma mark - WMFContentSource

- (void)startUpdating {
    self.isFetchingInitialLocation = NO;
    [self.currentLocationManager startMonitoringLocation];
}

- (void)stopUpdating {
    [self.currentLocationManager stopMonitoringLocation];
}

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    if (![WMFLocationManager isAuthorized]) {
        [self removeAllContent];
        if (completion) {
            completion();
        }
    } else if (self.currentLocationManager.location == nil) {
        self.isFetchingInitialLocation = YES;
        self.completion = completion;
        [self.currentLocationManager startMonitoringLocation];
    } else {
        [self getGroupForLocation:self.currentLocationManager.location
            completion:^(WMFLocationContentGroup *group) {
                [self fetchResultsForLocationGroup:group completion:completion];
            }
            failure:^(NSError *error) {
                if (completion) {
                    completion();
                }
            }];
    }
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:[WMFLocationContentGroup kind]];
}

#pragma mark - WMFLocationManagerDelegate

- (void)locationManager:(WMFLocationManager *)controller didUpdateLocation:(CLLocation *)location {
    if ([[NSDate date] timeIntervalSinceDate:[location timestamp]] < 60 * 60 && self.isFetchingInitialLocation) {
        [self stopUpdating];
    }
    self.isFetchingInitialLocation = NO;
    [self getGroupForLocation:location
        completion:^(WMFLocationContentGroup *group) {
            [self fetchResultsForLocationGroup:group completion:self.completion];
            self.completion = nil;
        }
        failure:^(NSError *error) {
            if (self.completion) {
                self.completion();
            }
            self.completion = nil;
        }];
}

- (void)locationManager:(WMFLocationManager *)controller didReceiveError:(NSError *)error {
    if (self.isFetchingInitialLocation) {
        [self stopUpdating];
    }
    self.isFetchingInitialLocation = NO;
    if (self.completion) {
        self.completion();
    }
    self.completion = nil;
}

- (nullable WMFLocationContentGroup *)contentGroupCloseToLocation:(CLLocation *)location {

    WMFLocationContentGroup *group = nil;
    [self.contentStore enumerateContentGroupsOfKind:[WMFLocationContentGroup kind]
                                          withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                              WMFLocationContentGroup *locationGroup = (id)group;
                                              if ([locationGroup.location wmf_isCloseTo:location]) {
                                                  group = locationGroup;
                                                  *stop = YES;
                                              }
                                          }];

    return group;
}

#pragma mark - Fetching

- (void)getGroupForLocation:(CLLocation *)location completion:(void (^)(WMFLocationContentGroup *group))completion
                    failure:(void (^)(NSError *error))failure {

    if (self.isProcessingLocation) {
        failure(nil);
        return;
    }
    self.isProcessingLocation = YES;

    WMFLocationContentGroup *group = [self contentGroupCloseToLocation:location];
    if (group) {
        completion(group);
        return;
    }

    [self.currentLocationManager reverseGeocodeLocation:location
        completion:^(CLPlacemark *_Nonnull placemark) {
            WMFLocationContentGroup *group = [[WMFLocationContentGroup alloc] initWithLocation:location placemark:placemark siteURL:self.siteURL];
            completion(group);

        }
        failure:^(NSError *_Nonnull error) {
            self.isProcessingLocation = NO;
            failure(error);
        }];
}

- (void)fetchResultsForLocationGroup:(WMFLocationContentGroup *)group completion:(nullable dispatch_block_t)completion {

    NSArray<NSURL *> *results = [self.contentStore contentForContentGroup:group];

    if ([results count] > 0) {
        self.isProcessingLocation = NO;
        if (completion) {
            completion();
        }
        return;
    }

    @weakify(self);
    [self.locationSearchFetcher fetchArticlesWithSiteURL:self.siteURL
        location:group.location
        resultLimit:20
        completion:^(WMFLocationSearchResults *_Nonnull results) {
            @strongify(self);
            NSArray<NSURL *> *urls = [results.results bk_map:^id(id obj) {
                return [results urlForResult:obj];
            }];
            [results.results enumerateObjectsUsingBlock:^(MWKLocationSearchResult *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                [self.previewStore addPreviewWithURL:urls[idx] updatedWithLocationSearchResult:obj];
            }];

            [self removeOldSectionsForDate:group.date];
            [self.contentStore addContentGroup:group associatedContent:urls];
            [self.contentStore notifyWhenWriteTransactionsComplete:completion];

            self.isProcessingLocation = NO;

        }
        failure:^(NSError *_Nonnull error) {
            self.isProcessingLocation = NO;
            if (completion) {
                completion();
            }
        }];
}

- (void)removeOldSectionsForDate:(NSDate *)date {
    NSMutableArray *oldSectionKeys = [NSMutableArray array];
    [self.contentStore enumerateContentGroupsOfKind:[WMFLocationContentGroup kind]
                                          withBlock:^(WMFContentGroup *_Nonnull section, BOOL *_Nonnull stop) {
                                              if ([[section.date dateAtStartOfDay] isEqualToDate:[date dateAtStartOfDay]]) {
                                                  [oldSectionKeys addObject:[section databaseKey]];
                                              }
                                          }];
    [self.contentStore readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        [transaction removeObjectsForKeys:oldSectionKeys inCollection:[WMFContentGroup databaseCollectionName]];
    }];
}

@end
