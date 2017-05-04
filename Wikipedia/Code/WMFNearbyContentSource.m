#import "WMFNearbyContentSource.h"
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

#import "WMFLocationManager.h"
#import "WMFLocationSearchFetcher.h"
#import "CLLocation+WMFComparison.h"

#import <WMF/WMF-Swift.h>

static const CLLocationDistance WMFNearbyUpdateDistanceThresholdInMeters = 25000;

static const NSInteger WMFNearbyDaysBetweenForcedUpdates = 10;
const CLLocationDistance WMFNearbyForcedUpdateDistanceThresholdInMeters = 1000;

@interface WMFNearbyContentSource () <WMFLocationManagerDelegate>

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (readwrite, nonatomic, strong) MWKDataStore *dataStore;
@property (nonatomic, strong, readwrite) WMFLocationManager *currentLocationManager;
@property (nonatomic, strong) WMFLocationSearchFetcher *locationSearchFetcher;

@property (readwrite, nonatomic, assign) BOOL isFetchingInitialLocation;

@property (readwrite, nonatomic, assign) BOOL isProcessingLocation;

@property (readwrite, nonatomic, copy) dispatch_block_t completion;

@end

@implementation WMFNearbyContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL dataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.dataStore = dataStore;
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

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(dispatch_block_t)completion {
    [moc performBlock:^{
        if (![WMFLocationManager isAuthorized]) {
            [moc removeAllContentGroupsOfKind:WMFContentGroupKindLocation];
            if (![[NSUserDefaults wmf_userDefaults] wmf_exploreDidPromptForLocationAuthorization]) {
                [self showAuthorizationPlaceholderInManagedObjectContext:moc
                                                              completion:^{
                                                                  if (completion) {
                                                                      completion();
                                                                  }
                                                              }];
            } else if (completion) {
                completion();
            }
            return;
        }

        [moc removeAllContentGroupsOfKind:WMFContentGroupKindLocationPlaceholder];

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
                inManagedObjectContext:moc
                force:force
                completion:^(WMFContentGroup *group, CLLocation *location, CLPlacemark *placemark) {
                    if (group && [group.content isKindOfClass:[NSArray class]] && group.content.count > 0) {
                        NSDate *now = [NSDate date];
                        NSDate *todayMidnightUTC = [now wmf_midnightUTCDateFromLocalDate];
                        if (force || (![[NSUserDefaults wmf_userDefaults] wmf_placesHasAppeared] && [[NSCalendar wmf_utcGregorianCalendar] wmf_daysFromDate:group.midnightUTCDate toDate:todayMidnightUTC] >= WMFNearbyDaysBetweenForcedUpdates)) {
                            group.date = now;
                            group.midnightUTCDate = todayMidnightUTC;
                        }
                        done();
                        return;
                    }
                    [self fetchResultsForLocation:location
                                        placemark:placemark
                           inManagedObjectContext:moc
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
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindLocation];
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindLocationPlaceholder];
}

- (void)showAuthorizationPlaceholderInManagedObjectContext:(NSManagedObjectContext *)moc completion:(nonnull dispatch_block_t)completion {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindLocation];
    NSURL *placeholderURL = [WMFContentGroup locationPlaceholderContentGroupURL];
    NSDate *date = [NSDate date];
    // Check for group for date to re-use the same group if it was updated today
    WMFContentGroup *group = [moc newestGroupOfKind:WMFContentGroupKindLocationPlaceholder];

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
            [moc performBlock:^{
                [moc fetchOrCreateArticleWithURL:articleURL updatedWithSearchResult:result];
                [moc fetchOrCreateGroupForURL:placeholderURL ofKind:WMFContentGroupKindLocationPlaceholder forDate:date withSiteURL:self.siteURL associatedContent:@[articleURL] customizationBlock:nil];
                completion();
            }];
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
    NSManagedObjectContext *moc = self.dataStore.viewContext;
    [self getGroupForLocation:location
        inManagedObjectContext:moc
        force:NO
        completion:^(WMFContentGroup *group, CLLocation *location, CLPlacemark *placemark) {
            if (group && [group.content isKindOfClass:[NSArray class]] && group.content.count > 0) {
                if (self.completion) {
                    self.completion();
                }
                self.completion = nil;
                return;
            }
            [self fetchResultsForLocation:location placemark:placemark inManagedObjectContext:moc completion:self.completion];
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

- (nullable WMFContentGroup *)contentGroupCloseToLocation:(CLLocation *)location inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force {
    NSDate *todayMidnightUTC = [[NSDate date] wmf_midnightUTCDateFromLocalDate];
    __block CLLocationDistance distanceThreshold = force ? WMFNearbyUpdateDistanceThresholdInMeters : WMFNearbyForcedUpdateDistanceThresholdInMeters;
    __block NSInteger daysUntilForcedUpdate = [[NSUserDefaults wmf_userDefaults] wmf_placesHasAppeared] ? NSIntegerMax : WMFNearbyDaysBetweenForcedUpdates;
    if (!force) {
        WMFContentGroup *newestContentGroup = [moc newestGroupOfKind:WMFContentGroupKindLocation];
        NSDate *newestMidnightUTCDate = newestContentGroup.midnightUTCDate;
        if (newestMidnightUTCDate && [[NSCalendar wmf_utcGregorianCalendar] wmf_daysFromDate:newestMidnightUTCDate toDate:todayMidnightUTC] >= daysUntilForcedUpdate) {
            distanceThreshold = WMFNearbyForcedUpdateDistanceThresholdInMeters;
        }
    }
    return [moc locationContentGroupWithinMeters:distanceThreshold ofLocation:location];
}

#pragma mark - Fetching

- (void)getGroupForLocation:(CLLocation *)location inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(void (^)(WMFContentGroup *group, CLLocation *location, CLPlacemark *placemark))completion failure:(void (^)(NSError *error))failure {

    if (self.isProcessingLocation || !location) {
        failure(nil);
        return;
    }
    self.isProcessingLocation = YES;

    [moc performBlock:^{
        WMFContentGroup *group = [self contentGroupCloseToLocation:location inManagedObjectContext:moc force:force];
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
    }];
}

- (void)fetchResultsForLocation:(CLLocation *)location placemark:(CLPlacemark *)placemark inManagedObjectContext:(NSManagedObjectContext *)moc completion:(nullable dispatch_block_t)completion {
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

            NSArray<MWKLocationSearchResult *> *locationSearchResults = results.results;
            NSMutableDictionary<NSURL *, MWKLocationSearchResult *> *resultsByURL = [NSMutableDictionary dictionaryWithCapacity:locationSearchResults.count];
            NSMutableArray<NSURL *> *orderedURLs = [NSMutableArray arrayWithCapacity:locationSearchResults.count];
            for (MWKLocationSearchResult *result in locationSearchResults) {
                NSURL *articleURL = [results urlForResult:result];
                if (articleURL) {
                    resultsByURL[articleURL] = result;
                    [orderedURLs addObject:articleURL];
                }
            }

            [moc performBlock:^{
                [resultsByURL enumerateKeysAndObjectsUsingBlock:^(NSURL *_Nonnull articleURL, MWKLocationSearchResult *_Nonnull result, BOOL *_Nonnull stop) {
                    [moc fetchOrCreateArticleWithURL:articleURL updatedWithSearchResult:result];
                }];
                WMFContentGroup *group = [moc createGroupOfKind:WMFContentGroupKindLocation
                                                        forDate:date
                                                    withSiteURL:self.siteURL
                                              associatedContent:orderedURLs
                                             customizationBlock:^(WMFContentGroup *_Nonnull group) {
                                                 group.location = location;
                                                 group.placemark = placemark;
                                             }];
                [self removeSectionsForMidnightUTCDate:group.midnightUTCDate withKeyNotEqualToKey:group.key inManagedObjectContext:moc];
                if (completion) {
                    completion();
                }
            }];

        }
        failure:^(NSError *_Nonnull error) {
            self.isProcessingLocation = NO;
            if (completion) {
                completion();
            }
        }];
}

- (void)removeSectionsForMidnightUTCDate:(NSDate *)midnightUTCDate withKeyNotEqualToKey:(NSString *)key inManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc enumerateContentGroupsOfKind:WMFContentGroupKindLocation
                            withBlock:^(WMFContentGroup *_Nonnull section, BOOL *_Nonnull stop) {
                                if ([section.midnightUTCDate isEqualToDate:midnightUTCDate] && ![section.key isEqualToString:key]) {
                                    [moc deleteObject:section];
                                }
                            }];
}

@end
