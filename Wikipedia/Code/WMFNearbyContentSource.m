#import "WMFNearbyContentSource.h"
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"
#import "CLLocation+WMFComparison.h"

#import <WMF/WMF-Swift.h>

static const CLLocationDistance WMFNearbyUpdateDistanceThresholdInMeters = 25000;

static const NSInteger WMFNearbyDaysBetweenForcedUpdates = 10;
static const CLLocationDistance WMFNearbyForcedUpdateDistanceThresholdInMeters = 1000;

@interface WMFNearbyContentSource () <WMFLocationManagerDelegate>

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFArticleDataStore *previewStore;

@property (nonatomic, strong, readwrite) WMFLocationManager *currentLocationManager;
@property (nonatomic, strong) WMFLocationSearchFetcher *locationSearchFetcher;

@property (readwrite, nonatomic, assign) BOOL isFetchingInitialLocation;

@property (readwrite, nonatomic, assign) BOOL isProcessingLocation;

@property (readwrite, nonatomic, copy) dispatch_block_t completion;

@end

@implementation WMFNearbyContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticleDataStore *)previewStore {
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
    if ([WMFLocationManager isAuthorized]) {
        [self.currentLocationManager startMonitoringLocation];
    }
}

- (void)stopUpdating {
    [self.currentLocationManager stopMonitoringLocation];
}

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    WMFContentGroupDataStore *cs = self.contentStore;
    [cs performBlockOnImportContext:^(NSManagedObjectContext * _Nonnull moc) {
        if (![WMFLocationManager isAuthorized]) {
            [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindLocation inManagedObjectContext:moc];
            if (![[NSUserDefaults wmf_userDefaults] wmf_exploreDidPromptForLocationAuthorization]) {
                [self showAuthorizationPlaceholderInManagedObjectContext:moc completion:^{
                    if (completion) {
                        completion();
                    }
                }];
            } else if (completion) {
                completion();
            }
            return;
        }
        
        [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindLocationPlaceholder inManagedObjectContext:moc];
        
        if (self.currentLocationManager.location == nil) {
            self.isFetchingInitialLocation = YES;
            self.completion = completion;
            [self.currentLocationManager startMonitoringLocation];
        } else {
            dispatch_block_t done = ^{
                if (completion) {
                    completion();
                }
            };
            [self getGroupForLocation:self.currentLocationManager.location
                           completion:^(WMFContentGroup *group, CLLocation *location, CLPlacemark *placemark) {
                               if (group && [group.content isKindOfClass:[NSArray class]] && group.content.count > 0) {
                                   NSDate *now = [NSDate date];
                                   NSDate *todayMidnightUTC = [now wmf_midnightUTCDateFromLocalDate];
                                   if (![[NSUserDefaults wmf_userDefaults] wmf_placesHasAppeared] && [[NSCalendar wmf_utcGregorianCalendar] wmf_daysFromDate:group.midnightUTCDate toDate:todayMidnightUTC] >= WMFNearbyDaysBetweenForcedUpdates) {
                                       group.date = now;
                                       group.midnightUTCDate = todayMidnightUTC;
                                   }
                                   done();
                                   return;
                               }
                               [self fetchResultsForLocation:location
                                                   placemark:placemark
                                                  completion:^{
                                                      done();
                                                  }];
                           }
                              failure:^(NSError *error) {
                                  done();
                              }];
        }
        
    }];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindLocation inManagedObjectContext:moc];
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindLocationPlaceholder inManagedObjectContext:moc];
}

- (void)showAuthorizationPlaceholderInManagedObjectContext:(NSManagedObjectContext *)moc completion:(nonnull dispatch_block_t)completion {
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindLocation inManagedObjectContext:moc];
    NSURL *placeholderURL = [WMFContentGroup locationPlaceholderContentGroupURL];
    NSDate *date = [NSDate date];
    // Check for group for date to re-use the same group if it was updated today
    WMFContentGroup *group = [self.contentStore firstGroupOfKind:WMFContentGroupKindLocationPlaceholder inManagedObjectContext:moc];

    if (group && (group.wasDismissed || [group.midnightUTCDate isEqualToDate:date.wmf_midnightUTCDateFromLocalDate])) {
        completion();
        return;
    }
    // If the group doesn't exist (or it doesn't exist for today) - Pick a new random article to show
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(48.86611, 2.31444);
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:center radius:40075000 identifier:@"world"];
    [self.locationSearchFetcher fetchArticlesWithSiteURL:self.siteURL
        inRegion:region
        matchingSearchTerm:nil
        sortStyle:WMFLocationSearchSortStyleLinks
        resultLimit:50
        completion:^(WMFLocationSearchResults *_Nonnull results) {
            NSInteger count = results.results.count;
            if (count <= 0) {
                completion();
                return;
            }
            uint32_t rand = arc4random_uniform((uint32_t)count);
            MWKLocationSearchResult *result = results.results[rand];
            NSURL *articleURL = [results urlForResult:result];
            if (!articleURL) {
                completion();
                return;
            }
            [self.previewStore addPreviewWithURL:articleURL updatedWithSearchResult:result inManagedObjectContext:moc];
            [self.contentStore fetchOrCreateGroupForURL:placeholderURL ofKind:WMFContentGroupKindLocationPlaceholder forDate:date withSiteURL:self.siteURL associatedContent:@[articleURL] inManagedObjectContext:moc customizationBlock:nil];
            completion();
        }
        failure:^(NSError *_Nonnull error) {
            completion();
        }];
}

#pragma mark - WMFLocationManagerDelegate

- (void)locationManager:(WMFLocationManager *)controller didUpdateLocation:(CLLocation *)location {
    if ([[NSDate date] timeIntervalSinceDate:[location timestamp]] < 60 * 60 && self.isFetchingInitialLocation) {
        [self stopUpdating];
    }
    self.isFetchingInitialLocation = NO;
    [self getGroupForLocation:location
        completion:^(WMFContentGroup *group, CLLocation *location, CLPlacemark *placemark) {
            if (group && [group.content isKindOfClass:[NSArray class]] && group.content.count > 0) {
                if (self.completion) {
                    self.completion();
                }
                self.completion = nil;
                return;
            }
            [self fetchResultsForLocation:location placemark:placemark completion:self.completion];
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

- (nullable WMFContentGroup *)contentGroupCloseToLocation:(CLLocation *)location {
    NSDate *todayMidnightUTC = [[NSDate date] wmf_midnightUTCDateFromLocalDate];
    __block WMFContentGroup *locationContentGroup = nil;
    __block NSDate *newestMidnightUTCDate = nil;
    __block CLLocationDistance distanceThreshold = WMFNearbyUpdateDistanceThresholdInMeters;
    __block NSInteger daysUntilForcedUpdate = [[NSUserDefaults wmf_userDefaults] wmf_placesHasAppeared] ? NSIntegerMax : WMFNearbyDaysBetweenForcedUpdates;
    [self.contentStore enumerateContentGroupsOfKind:WMFContentGroupKindLocation
                                        sortedByKey:@"midnightUTCDate"
                                          ascending:NO
                                          withBlock:^(WMFContentGroup *_Nonnull currentGroup, BOOL *_Nonnull stop) {
                                              if (!newestMidnightUTCDate) {
                                                  newestMidnightUTCDate = currentGroup.midnightUTCDate;
                                                  if ([[NSCalendar wmf_utcGregorianCalendar] wmf_daysFromDate:newestMidnightUTCDate toDate:todayMidnightUTC] >= daysUntilForcedUpdate) {
                                                      distanceThreshold = WMFNearbyForcedUpdateDistanceThresholdInMeters;
                                                  }
                                              }
                                              WMFContentGroup *potentiallyCloseLocationGroup = (WMFContentGroup *)currentGroup;
                                              CLLocation *groupLocation = potentiallyCloseLocationGroup.location;
                                              if (!groupLocation) {
                                                  return;
                                              }
                                              CLLocationDistance distance = [groupLocation distanceFromLocation:location];
                                              if (distance < distanceThreshold) {
                                                  locationContentGroup = potentiallyCloseLocationGroup;
                                                  *stop = YES;
                                              }
                                          }];

    return locationContentGroup;
}

#pragma mark - Fetching

- (void)getGroupForLocation:(CLLocation *)location completion:(void (^)(WMFContentGroup *group, CLLocation *location, CLPlacemark *placemark))completion
                    failure:(void (^)(NSError *error))failure {

    if (self.isProcessingLocation || !location) {
        failure(nil);
        return;
    }
    self.isProcessingLocation = YES;

    WMFContentGroup *group = [self contentGroupCloseToLocation:location];
    if (group) {
        self.isProcessingLocation = NO;
        completion(group, group.location, group.placemark);
        return;
    }

    [self.currentLocationManager reverseGeocodeLocation:location
        completion:^(CLPlacemark *_Nonnull placemark) {
            completion(nil, location, placemark);
            self.isProcessingLocation = NO;
        }
        failure:^(NSError *_Nonnull error) {
            self.isProcessingLocation = NO;
            failure(error);
        }];
}

- (void)fetchResultsForLocation:(CLLocation *)location placemark:(CLPlacemark *)placemark completion:(nullable dispatch_block_t)completion {
    NSDate *date = [NSDate date];
    @weakify(self);
    [self.locationSearchFetcher fetchArticlesWithSiteURL:self.siteURL
        location:location
        resultLimit:20
        completion:^(WMFLocationSearchResults *_Nonnull results) {
            @strongify(self);
            self.isProcessingLocation = NO;

            if ([results.results count] == 0) {
                if (completion) {
                    completion();
                }
                return;
            }

            NSArray<NSURL *> *urls = [results.results wmf_map:^id(id obj) {
                return [results urlForResult:obj];
            }];

            [results.results enumerateObjectsUsingBlock:^(MWKLocationSearchResult *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                [self.previewStore addPreviewWithURL:urls[idx] updatedWithLocationSearchResult:obj];
            }];

            WMFContentGroup *group = [self.contentStore createGroupOfKind:WMFContentGroupKindLocation
                                                                  forDate:date
                                                              withSiteURL:self.siteURL
                                                        associatedContent:nil
                                                       customizationBlock:^(WMFContentGroup *_Nonnull group) {
                                                           group.location = location;
                                                           group.placemark = placemark;
                                                       }];
            [self removeSectionsForMidnightUTCDate:group.midnightUTCDate withKeyNotEqualToKey:group.key];
            group.content = urls;
            if (completion) {
                completion();
            }
        }
        failure:^(NSError *_Nonnull error) {
            self.isProcessingLocation = NO;
            if (completion) {
                completion();
            }
        }];
}

- (void)removeSectionsForMidnightUTCDate:(NSDate *)midnightUTCDate withKeyNotEqualToKey:(NSString *)key {
    NSMutableArray *oldSectionKeys = [NSMutableArray array];
    [self.contentStore enumerateContentGroupsOfKind:WMFContentGroupKindLocation
                                          withBlock:^(WMFContentGroup *_Nonnull section, BOOL *_Nonnull stop) {
                                              if ([section.midnightUTCDate isEqualToDate:midnightUTCDate] && ![section.key isEqualToString:key]) {
                                                  [oldSectionKeys addObject:key];
                                              }
                                          }];
    [self.contentStore removeContentGroupsWithKeys:oldSectionKeys];
}

@end
