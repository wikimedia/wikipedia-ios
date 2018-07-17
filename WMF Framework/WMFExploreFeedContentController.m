#import <WMF/WMFExploreFeedContentController.h>
#import <WMF/WMFRelatedPagesContentSource.h>
#import <WMF/WMFNearbyContentSource.h>
#import <WMF/WMFContinueReadingContentSource.h>
#import <WMF/WMFFeedContentSource.h>
#import <WMF/WMFRandomContentSource.h>
#import <WMF/WMFAnnouncementsContentSource.h>
#import <WMF/WMFOnThisDayContentSource.h>
#import <WMF/WMFAssertions.h>
#import <WMF/WMF-Swift.h>

NSString *const WMFExploreFeedContentControllerBusyStateDidChange = @"WMFExploreFeedContentControllerBusyStateDidChange";
const NSInteger WMFExploreFeedMaximumNumberOfDays = 30;
static const NSTimeInterval WMFFeedRefreshTimeoutInterval = 12;
static NSTimeInterval WMFFeedRefreshBackgroundTimeout = 30;
static const NSString *kvo_WMFExploreFeedContentController_operationQueue_operationCount = @"kvo_WMFExploreFeedContentController_operationQueue_operationCount";

NSString *const WMFExploreFeedPreferencesKey = @"WMFExploreFeedPreferencesKey";
NSString *const WMFExploreFeedPreferencesGlobalCardsKey = @"WMFExploreFeedPreferencesGlobalCardsKey";
NSString *const WMFExploreFeedPreferencesDidChangeNotification = @"WMFExploreFeedPreferencesDidChangeNotification";
NSString *const WMFExploreFeedPreferencesDidSaveNotification = @"WMFExploreFeedPreferencesDidSaveNotification";
NSString *const WMFNewExploreFeedPreferencesWereRejectedNotification = @"WMFNewExploreFeedPreferencesWereRejectedNotification";

@interface WMFExploreFeedContentController ()

@property (nonatomic, strong) NSArray<id<WMFContentSource>> *contentSources;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSDictionary *exploreFeedPreferences;
@property (nonatomic, copy, readonly) NSSet <NSURL *> *preferredSiteURLs;
@property (nonatomic, strong) ExploreFeedPreferencesUpdateCoordinator *exploreFeedPreferencesUpdateCoordinator;

@end

@implementation WMFExploreFeedContentController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.dataStore.viewContext];
    }
    return self;
}

- (void)dealloc {
    self.operationQueue = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setOperationQueue:(NSOperationQueue *)operationQueue {
    if (_operationQueue == operationQueue) {
        return;
    }

    if (_operationQueue) {
        [_operationQueue removeObserver:self forKeyPath:@"operationCount"];
    }

    _operationQueue = operationQueue;

    if (_operationQueue) {
        [_operationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:&kvo_WMFExploreFeedContentController_operationQueue_operationCount];
    }
}

- (void)setDataStore:(MWKDataStore *)dataStore {
    _dataStore = dataStore;
    self.exploreFeedPreferences = [self exploreFeedPreferencesInManagedObjectContext:dataStore.viewContext];
    self.exploreFeedPreferencesUpdateCoordinator = [[ExploreFeedPreferencesUpdateCoordinator alloc] initWithFeedContentController:self];
}

#pragma mark - Content Sources

- (WMFFeedContentSource *)feedContentSource {
    return [self.contentSources wmf_match:^BOOL(id<WMFContentSource> obj) {
        return [obj isKindOfClass:[WMFFeedContentSource class]];
    }];
}

- (WMFRandomContentSource *)randomContentSource {
    return [self.contentSources wmf_match:^BOOL(id<WMFContentSource> obj) {
        return [obj isKindOfClass:[WMFRandomContentSource class]];
    }];
}
- (WMFNearbyContentSource *)nearbyContentSource {
    return [self.contentSources wmf_match:^BOOL(id<WMFContentSource> obj) {
        return [obj isKindOfClass:[WMFNearbyContentSource class]];
    }];
}

- (NSArray<id<WMFContentSource>> *)contentSources {
    NSParameterAssert(self.dataStore);
    NSParameterAssert(self.siteURLs);
    if (!_contentSources) {
        NSMutableArray *mutableContentSources = [NSMutableArray arrayWithCapacity:2 + self.siteURLs.count * 7];
        [mutableContentSources addObject:[[WMFRelatedPagesContentSource alloc] init]];
        [mutableContentSources addObject:[[WMFContinueReadingContentSource alloc] initWithUserDataStore:self.dataStore]];
        for (NSURL *siteURL in self.siteURLs) {
            WMFFeedContentSource *feedContentSource = [[WMFFeedContentSource alloc] initWithSiteURL:siteURL
                                                                                      userDataStore:self.dataStore
                                                                            notificationsController:[WMFNotificationsController sharedNotificationsController]];
            feedContentSource.notificationSchedulingEnabled = YES;
            [mutableContentSources addObjectsFromArray: @[[[WMFNearbyContentSource alloc] initWithSiteURL:siteURL  dataStore:self.dataStore],
                                feedContentSource,
                                [[WMFRandomContentSource alloc] initWithSiteURL:siteURL],
                                [[WMFAnnouncementsContentSource alloc] initWithSiteURL:siteURL],
                                [[WMFOnThisDayContentSource alloc] initWithSiteURL:siteURL]]];
        }
        _contentSources = [mutableContentSources copy];
    }
    return _contentSources;
}

#pragma mark - Start / Stop

- (void)startContentSources {
    [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(WMFAutoUpdatingContentSource)]) {
            [(id<WMFAutoUpdatingContentSource>)obj startUpdating];
        }
    }];
}

- (void)stopContentSources {
    [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(WMFAutoUpdatingContentSource)]) {
            [(id<WMFAutoUpdatingContentSource>)obj stopUpdating];
        }
    }];
}

#pragma mark - Updating

- (void)updateFeedSourcesUserInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion {
    [self updateFeedSourcesWithDate:nil userInitiated:wasUserInitiated completion:completion];
}

- (void)updateFeedSourcesWithDate:(nullable NSDate *)date userInitiated:(BOOL)wasUserInitiated completion:(nullable dispatch_block_t)completion {
    WMFAssertMainThread(@"updateFeedSources: must be called on the main thread");
    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation *_Nonnull op) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSManagedObjectContext *moc = self.dataStore.feedImportContext;
            WMFTaskGroup *group = [WMFTaskGroup new];
#if DEBUG
            NSMutableArray *entered = [NSMutableArray arrayWithCapacity:self.contentSources.count];
#endif
            [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                [group enter];
#if DEBUG
                NSString *classString = NSStringFromClass([obj class]);
                @synchronized(self) {
                    [entered addObject:classString];
                }
#endif
                dispatch_block_t contentSourceCompletion = ^{
#if DEBUG
                    @synchronized(self) {
                        NSInteger index = [entered indexOfObject:classString];
                        assert(index != NSNotFound);
                        [entered removeObjectAtIndex:index];
                    }
#endif
                    [group leave];
                };

                if ([obj conformsToProtocol:@protocol(WMFOptionalNewContentSource)]) {
                    NSDate *optionalDate = date ? date : [NSDate date];
                    id<WMFOptionalNewContentSource> optional = (id<WMFOptionalNewContentSource>)obj;
                    [optional loadContentForDate:optionalDate inManagedObjectContext:moc force:NO addNewContent:wasUserInitiated completion:contentSourceCompletion];
                } else if (date && [obj conformsToProtocol:@protocol(WMFDateBasedContentSource)]) {
                    id<WMFDateBasedContentSource> dateBased = (id<WMFDateBasedContentSource>)obj;
                    [dateBased loadContentForDate:date inManagedObjectContext:moc force:NO completion:contentSourceCompletion];
                } else if (!date) {
                    [obj loadNewContentInManagedObjectContext:moc force:NO completion:contentSourceCompletion];
                } else {
                    contentSourceCompletion();
                }
            }];

            [group waitInBackgroundWithTimeout:WMFFeedRefreshTimeoutInterval
                                    completion:^{
                                        [moc performBlock:^{
                                            NSError *saveError = nil;
                                            if ([moc hasChanges]) {
                                                if (date) {
                                                    [self applyExploreFeedPreferencesToAllObjectsInManagedObjectContext:moc];
                                                } else {
                                                    [self applyExploreFeedPreferencesToUpdatedObjectsInManagedObjectContext:moc];
                                                }
                                                if (![moc save:&saveError]) {
                                                    DDLogError(@"Error saving: %@", saveError);
                                                }
                                            }
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self.dataStore teardownFeedImportContext];
                                                [[NSUserDefaults wmf_userDefaults] wmf_setFeedRefreshDate:[NSDate date]];
                                                if (completion) {
                                                    completion();
                                                }
                                                [op finish];
                                            });
                                        }];

#if DEBUG
                                        if ([entered count] > 0) {
                                            DDLogError(@"Didn't leave: %@", entered);
                                        }
#endif
                                    }];
        });
    }];

    [self.operationQueue addOperation:op];
}

- (void)updateNearbyForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    WMFAssertMainThread(@"updateNearby: must be called on the main thread");

    NSManagedObjectContext *moc = self.dataStore.viewContext;
    WMFTaskGroup *group = [WMFTaskGroup new];
    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation *_Nonnull op) {
        [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj isKindOfClass:[WMFNearbyContentSource class]]) {
                [group enter];
                [obj loadNewContentInManagedObjectContext:moc
                                                    force:force
                                               completion:^{
                                                   [group leave];
                                               }];
            }
        }];

        [group waitInBackgroundWithTimeout:WMFFeedRefreshTimeoutInterval
                                completion:^{
                                    [moc performBlock:^{
                                        NSError *saveError = nil;
                                        if ([moc hasChanges] && ![moc save:&saveError]) {
                                            DDLogError(@"Error saving: %@", saveError);
                                        }
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            if (completion) {
                                                completion();
                                            }
                                            [op finish];
                                        });
                                    }];
                                }];

    }];

    [self.operationQueue addOperation:op];
}

- (void)updateBackgroundSourcesWithCompletion:(void (^_Nonnull)(UIBackgroundFetchResult))completionHandler {
    WMFAssertMainThread(@"updateBackgroundSourcesWithCompletion: must be called on the main thread");

    NSManagedObjectContext *moc = self.dataStore.viewContext;
    NSFetchRequest *beforeFetchRequest = [WMFContentGroup fetchRequest];
    NSInteger beforeCount = [moc countForFetchRequest:beforeFetchRequest error:nil];

    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation *_Nonnull op) {
        WMFTaskGroup *group = [WMFTaskGroup new];
        [group enter];
        [[self feedContentSource] loadNewContentInManagedObjectContext:moc
                                                                 force:NO
                                                            completion:^{
                                                                [group leave];
                                                            }];

        [group enter];
        [[self randomContentSource] loadNewContentInManagedObjectContext:moc
                                                                   force:NO
                                                              completion:^{
                                                                  [group leave];
                                                              }];

        [group waitInBackgroundWithTimeout:WMFFeedRefreshBackgroundTimeout
                                completion:^{
                                    [moc performBlock:^{
                                        BOOL didUpdate = NO;
                                        if ([moc hasChanges]) {
                                            NSFetchRequest *afterFetchRequest = [WMFContentGroup fetchRequest];
                                            NSInteger afterCount = [moc countForFetchRequest:afterFetchRequest error:nil];
                                            didUpdate = afterCount != beforeCount;
                                            NSError *saveError = nil;
                                            if (![moc save:&saveError]) {
                                                DDLogError(@"Error saving background source update: %@", saveError);
                                            }
                                        }
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            if (completionHandler) {
                                                completionHandler(didUpdate ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
                                            }
                                            [op finish];
                                        });
                                    }];
                                }];
    }];
    [self.operationQueue addOperation:op];
}

#pragma mark - Preferences

- (void)viewContextDidSave:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    NSArray<NSString *> *keys = @[NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey, NSRefreshedObjectsKey, NSInvalidatedObjectsKey];
    for (NSString *key in keys) {
        NSSet<NSManagedObject *> *savedObjects = userInfo[key];
        for (NSManagedObject *object in savedObjects) {
            if (![object isKindOfClass:[WMFKeyValue class]]) {
                continue;
            }
            WMFKeyValue *keyValue = (WMFKeyValue *)object;
            if (![keyValue.key isEqualToString:WMFExploreFeedPreferencesKey]) {
                continue;
            }
            NSDictionary *newExploreFeedPreferences = (NSDictionary *)keyValue.value;
            if (self.exploreFeedPreferences == newExploreFeedPreferences) {
                return;
            }
            self.exploreFeedPreferences = newExploreFeedPreferences;
            [NSNotificationCenter.defaultCenter postNotificationName:WMFExploreFeedPreferencesDidSaveNotification object:self.exploreFeedPreferences];
        }
    }
}

- (BOOL)anyContentGroupsVisibleInTheFeedForSiteURL:(NSURL *)siteURL {
    return [self.exploreFeedPreferences objectForKey:siteURL.wmf_articleDatabaseKey] != nil;
}

- (NSSet<NSString *> *)languageCodesForContentGroupKind:(WMFContentGroupKind)contentGroupKind {
    NSMutableSet *languageCodes = [NSMutableSet new];
    [self.exploreFeedPreferences enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSSet<NSNumber *> *value, BOOL * _Nonnull stop) {
        if (![value isKindOfClass:[NSDictionary class]] && [value containsObject:@(contentGroupKind)]) {
            [languageCodes addObject:[[NSURL URLWithString:key] wmf_language]];
        }
    }];
    return languageCodes;
}

+ (NSSet<NSNumber *> *)customizableContentGroupKindNumbers {
    static NSSet *customizableContentGroupKindNumbers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        customizableContentGroupKindNumbers = [NSSet setWithArray:@[@(WMFContentGroupKindFeaturedArticle), @(WMFContentGroupKindNews), @(WMFContentGroupKindTopRead), @(WMFContentGroupKindOnThisDay), @(WMFContentGroupKindLocation), @(WMFContentGroupKindLocationPlaceholder), @(WMFContentGroupKindRandom)]];
    });
    return customizableContentGroupKindNumbers;
}

+ (NSSet<NSNumber *> *)globalContentGroupKindNumbers {
    static NSSet *globalContentGroupKindNumbers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalContentGroupKindNumbers = [NSSet setWithArray:@[@(WMFContentGroupKindPictureOfTheDay), @(WMFContentGroupKindContinueReading), @(WMFContentGroupKindRelatedPages)]];
    });
    return globalContentGroupKindNumbers;
}

- (BOOL)isGlobalContentGroupKindInFeed:(WMFContentGroupKind)contentGroupKind {
    NSAssert([self isGlobal:contentGroupKind], @"Content group kind is not global");
    NSNumber *globalCardPreferenceNumber = [self.globalCardPreferences objectForKey:@(contentGroupKind)];
    return [globalCardPreferenceNumber boolValue];
}

- (BOOL)isGlobal:(WMFContentGroupKind)contentGroupKind {
    return [[WMFExploreFeedContentController globalContentGroupKindNumbers] containsObject:@(contentGroupKind)];
}

- (NSDictionary<NSNumber*, NSNumber*> *)globalCardPreferences {
    NSDictionary<NSNumber*, NSNumber*> *globalCardPreferences = [self.exploreFeedPreferences objectForKey:WMFExploreFeedPreferencesGlobalCardsKey] ?: [self defaultGlobalCardsPreferences];
    return globalCardPreferences;
}

- (BOOL)areGlobalContentGroupKindsInFeed {
    for (NSNumber *globalCardPreferenceNumber in [self.globalCardPreferences allValues]) {
        if ([globalCardPreferenceNumber boolValue]) {
            return true;
        }
        continue;
    }
    return false;
}

- (NSSet <NSURL *> *)preferredSiteURLs {
    return [NSSet setWithArray:[MWKLanguageLinkController sharedInstance].preferredSiteURLs];
}

- (NSDictionary *)exploreFeedPreferencesInManagedObjectContext:(NSManagedObjectContext *)moc {
    WMFKeyValue *keyValue = [moc wmf_keyValueForKey:WMFExploreFeedPreferencesKey];
    NSDictionary *exploreFeedPreferences = (NSDictionary *)keyValue.value;
    if (exploreFeedPreferences && [exploreFeedPreferences objectForKey:WMFExploreFeedPreferencesGlobalCardsKey]) {
        return exploreFeedPreferences;
    }
    NSMutableDictionary *newPreferences = [NSMutableDictionary dictionaryWithCapacity:self.preferredSiteURLs.count];
    for (NSURL *siteURL in self.preferredSiteURLs) {
        [newPreferences setObject:[WMFExploreFeedContentController customizableContentGroupKindNumbers] forKey:siteURL.wmf_articleDatabaseKey];
    }
    [newPreferences setObject:[self defaultGlobalCardsPreferences] forKey:WMFExploreFeedPreferencesGlobalCardsKey];
    [moc wmf_setValue:newPreferences forKey:WMFExploreFeedPreferencesKey];
    [self save:moc];
    NSDictionary *preferences = (NSDictionary *)[moc wmf_keyValueForKey:WMFExploreFeedPreferencesKey].value;
    assert(preferences);
    return preferences;
}

- (NSDictionary<NSNumber*, NSNumber*> *)defaultGlobalCardsPreferences {
    NSMutableDictionary<NSNumber*, NSNumber*> *defaultGlobalCardsPreferences = [NSMutableDictionary new];
    for (NSNumber *globalContentGroupKindNumber in [WMFExploreFeedContentController globalContentGroupKindNumbers]) {
        [defaultGlobalCardsPreferences setObject:[NSNumber numberWithBool:YES] forKey:globalContentGroupKindNumber];
    }
    return defaultGlobalCardsPreferences;
}

- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind isOn:(BOOL)isOn {
    [self toggleContentGroupOfKind:contentGroupKind forSiteURLs:self.preferredSiteURLs isOn:isOn];
}

- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind isOn:(BOOL)isOn forSiteURL:(NSURL *)siteURL {
    [self toggleContentGroupOfKind:contentGroupKind forSiteURLs:[NSSet setWithObject:siteURL] isOn:isOn];
}

-(void)toggleContentForSiteURL:(NSURL *)siteURL isOn:(BOOL)isOn updateFeed:(BOOL)updateFeed {
    [self updateExploreFeedPreferences:^(NSMutableDictionary *newPreferences) {
        NSString *key = siteURL.wmf_articleDatabaseKey;
        if (isOn) {
            [newPreferences setObject:[WMFExploreFeedContentController customizableContentGroupKindNumbers] forKey:key];
        } else {
            if ([newPreferences objectForKey:key]) {
                [newPreferences removeObjectForKey:key];
            }
        }
    } willTurnOnContentGroupOrLanguage:isOn];
}

- (void)toggleContentGroupOfKind:(WMFContentGroupKind)contentGroupKind forSiteURLs:(NSSet<NSURL *> *)siteURLs isOn:(BOOL)isOn {
    [self updateExploreFeedPreferences:^(NSMutableDictionary *newPreferences) {
        if ([self isGlobal:contentGroupKind]) {
            NSDictionary<NSNumber*, NSNumber*> *oldGlobalCardPreferences = [newPreferences objectForKey:WMFExploreFeedPreferencesGlobalCardsKey] ?: [self defaultGlobalCardsPreferences];
            NSMutableDictionary<NSNumber*, NSNumber*> *newGlobalCardPreferences = [oldGlobalCardPreferences mutableCopy];
            [newGlobalCardPreferences setObject:[NSNumber numberWithBool:isOn] forKey:@(contentGroupKind)];
            [newPreferences setObject:newGlobalCardPreferences forKey:WMFExploreFeedPreferencesGlobalCardsKey];
        } else {
            for (NSURL *siteURL in siteURLs) {
                NSString *key = siteURL.wmf_articleDatabaseKey;
                NSSet *oldVisibleContentGroupKindNumbers = [newPreferences objectForKey:key];
                NSMutableSet *newVisibleContentGroupKindNumbers;

                if (oldVisibleContentGroupKindNumbers) {
                    newVisibleContentGroupKindNumbers = [oldVisibleContentGroupKindNumbers mutableCopy];
                } else {
                    newVisibleContentGroupKindNumbers = [NSMutableSet set];
                }

                if (isOn) {
                    [newVisibleContentGroupKindNumbers addObject:@(contentGroupKind)];
                } else {
                    [newVisibleContentGroupKindNumbers removeObject:@(contentGroupKind)];
                }

                BOOL isPlaces = contentGroupKind == WMFContentGroupKindLocation || contentGroupKind == WMFContentGroupKindLocationPlaceholder;
                if (isPlaces) {
                    WMFContentGroupKind otherPlacesContentGroupKind = contentGroupKind == WMFContentGroupKindLocation ? WMFContentGroupKindLocationPlaceholder : WMFContentGroupKindLocation;
                    if (isOn) {
                        [newVisibleContentGroupKindNumbers addObject:@(otherPlacesContentGroupKind)];
                    } else {
                        [newVisibleContentGroupKindNumbers removeObject:@(otherPlacesContentGroupKind)];
                    }
                }

                if (newVisibleContentGroupKindNumbers.count == 0) {
                    [newPreferences removeObjectForKey:key];
                } else {
                    [newPreferences setObject:newVisibleContentGroupKindNumbers forKey:key];
                }
            }
        }
    } willTurnOnContentGroupOrLanguage:isOn];
}

- (void)toggleGlobalContentGroupKinds:(BOOL)on {
    [self updateExploreFeedPreferences:^(NSMutableDictionary *newPreferences) {
        NSDictionary<NSNumber*, NSNumber*> *oldGlobalCardPreferences = [newPreferences objectForKey:WMFExploreFeedPreferencesGlobalCardsKey] ?: [self defaultGlobalCardsPreferences];
        NSMutableDictionary<NSNumber*, NSNumber*> *newGlobalCardPreferences = [oldGlobalCardPreferences mutableCopy];
        for (id key in newGlobalCardPreferences.allKeys) {
            [newGlobalCardPreferences setObject:[NSNumber numberWithBool:on] forKey:key];
        }
        [newPreferences setObject:newGlobalCardPreferences forKey:WMFExploreFeedPreferencesGlobalCardsKey];
    } willTurnOnContentGroupOrLanguage:on];
}

- (void)saveNewExploreFeedPreferences:(NSDictionary *)newExploreFeedPreferences updateFeed:(BOOL)updateFeed {
    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation *_Nonnull op) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSManagedObjectContext *moc = self.dataStore.feedImportContext;
            [moc performBlock:^{
                [moc wmf_setValue:newExploreFeedPreferences forKey:WMFExploreFeedPreferencesKey];
                [self applyExploreFeedPreferencesToAllObjectsInManagedObjectContext:moc];
                [self save:moc];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (updateFeed) {
                        [self updateFeedSourcesUserInitiated:YES completion:nil];
                    }
                    [op finish];
                });
            }];
        });
    }];
    [self.operationQueue addOperation:op];
}

- (void)rejectNewExploreFeedPreferences {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:WMFNewExploreFeedPreferencesWereRejectedNotification object:nil];
    });
}

- (void)updateExploreFeedPreferences:(void(^)(NSMutableDictionary *newPreferences))update willTurnOnContentGroupOrLanguage:(BOOL)willTurnOnContentGroupOrLanguage {
    WMFAssertMainThread(@"updateExploreFeedPreferences: must be called on the main thread");
    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation *_Nonnull op) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSManagedObjectContext *moc = self.dataStore.feedImportContext;
            [moc performBlock:^{
                NSDictionary *oldPreferences = [self exploreFeedPreferencesInManagedObjectContext:moc];
                assert(oldPreferences);
                NSMutableDictionary *newPreferences = [oldPreferences mutableCopy];
                update(newPreferences);
                [self.exploreFeedPreferencesUpdateCoordinator configureWithOldExploreFeedPreferences:oldPreferences newExploreFeedPreferences:newPreferences willTurnOnContentGroupOrLanguage:willTurnOnContentGroupOrLanguage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:WMFExploreFeedPreferencesDidChangeNotification object:self.exploreFeedPreferencesUpdateCoordinator];
                    [op finish];
                });
            }];
        });
    }];
    [self.operationQueue addOperation:op];
}

- (void)applyExploreFeedPreferencesToAllObjectsInManagedObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    NSError *error = nil;
    NSArray<WMFContentGroup *> *contentGroups = [moc executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Error fetching WMFContentGroup: %@", error);
    }
    [self applyExploreFeedPreferencesToObjects:contentGroups inManagedObjectContext:moc];
}

- (void)applyExploreFeedPreferencesToObjects:(id<NSFastEnumeration>)objects inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSDictionary *preferences = [self exploreFeedPreferencesInManagedObjectContext:moc];
    for (NSManagedObject *object in objects) {
        if (![object isKindOfClass:[WMFContentGroup class]]) {
            continue;
        }
        WMFContentGroup *contentGroup = (WMFContentGroup *)object;
        if ([self isGlobal:contentGroup.contentGroupKind]) {
            BOOL isGlobalCardVisible = [[self.globalCardPreferences objectForKey:@(contentGroup.contentGroupKind)] boolValue];
            contentGroup.isVisible = isGlobalCardVisible;
        } else {
            NSSet<NSNumber *> *visibleContentGroupKinds = [preferences objectForKey:contentGroup.siteURL.wmf_articleDatabaseKey];
            NSNumber *contentGroupNumber = @(contentGroup.contentGroupKindInteger);
            if (![[WMFExploreFeedContentController customizableContentGroupKindNumbers] containsObject:contentGroupNumber]) {
                continue;
            }
            if ([visibleContentGroupKinds containsObject:contentGroupNumber]) {
                contentGroup.isVisible = !contentGroup.wasDismissed;
            } else {
                contentGroup.isVisible = NO;
            }
        }
    }
}

- (void)applyExploreFeedPreferencesToUpdatedObjectsInManagedObjectContext:(NSManagedObjectContext *)moc {
    [self applyExploreFeedPreferencesToObjects:[moc updatedObjects] inManagedObjectContext:moc];
}

- (void)save:(NSManagedObjectContext *)moc {
    NSError *error = nil;
    if (moc.hasChanges && ![moc save:&error]) {
        DDLogError(@"Error saving WMFExploreFeedContentController managedObjectContext");
    }
}

#pragma mark - SiteURL

- (void)setSiteURLs:(NSURL *)siteURLs {
    _siteURLs = [siteURLs copy];
    if ([_contentSources count] == 0) {
        return;
    }
    [self stopContentSources];
    self.contentSources = nil;
    [self startContentSources];
    [self updateFeedSourcesUserInitiated:NO completion:NULL];
}

#if WMF_TWEAKS_ENABLED
- (void)debugSendRandomInTheNewsNotification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        [[WMFNotificationsController sharedNotificationsController] requestAuthenticationIfNecessaryWithCompletionHandler:^(BOOL granted, NSError *_Nullable error) {
            if (!granted) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                WMFContentGroup *newsContentGroup = [self.dataStore.viewContext newestGroupOfKind:WMFContentGroupKindNews];
                if (newsContentGroup) {
                    NSArray<WMFFeedNewsStory *> *stories = (NSArray<WMFFeedNewsStory *> *)newsContentGroup.content;
                    if (stories.count > 0) {
                        NSInteger randomIndex = (NSInteger)arc4random_uniform((uint32_t)stories.count);
                        WMFFeedNewsStory *randomStory = stories[randomIndex];
                        WMFFeedArticlePreview *feedPreview = randomStory.featuredArticlePreview ?: randomStory.articlePreviews[0];
                        WMFArticle *preview = [self.dataStore fetchArticleWithURL:feedPreview.articleURL];
                        [[self feedContentSource] scheduleNotificationForNewsStory:randomStory articlePreview:preview inManagedObjectContext:self.dataStore.viewContext force:YES];
                    }
                }
            });
        }];
    });
}
#endif

#if DEBUG
#pragma mark - Debug

- (void)debugChaos {
    BOOL needsTeardown = arc4random_uniform(2) > 0;
    NSManagedObjectContext *moc = needsTeardown ? self.dataStore.feedImportContext : self.dataStore.viewContext;
    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation *_Nonnull op) {
        [moc performBlock:^{
            NSFetchRequest *request = [WMFContentGroup fetchRequest];
            NSInteger count = [moc countForFetchRequest:request error:nil];
            request.fetchLimit = (NSUInteger)arc4random_uniform((uint32_t)count);
            request.fetchOffset = (NSUInteger)arc4random_uniform((uint32_t)(count - request.fetchLimit));
            NSArray *results = [moc executeFetchRequest:request error:nil];
            for (WMFContentGroup *group in results) {
                uint32_t seed = arc4random_uniform(5);
                int32_t random = (15 - (int32_t)arc4random_uniform(30));
                switch (seed) {
                    case 0:
                        group.midnightUTCDate = [group.midnightUTCDate dateByAddingTimeInterval:86400 * random];
                        group.contentMidnightUTCDate = [group.contentMidnightUTCDate dateByAddingTimeInterval:86400 * random];
                        group.date = [group.date dateByAddingTimeInterval:86400 * random];
                        break;
                    case 1:
                        [moc deleteObject:group];
                    case 2:
                        group.dailySortPriority = group.dailySortPriority + random;
                    default:
                        break;
                }
            }
            NSError *saveError = nil;
            if ([moc hasChanges] && ![moc save:&saveError]) {
                DDLogError(@"chaos error: %@", saveError);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (needsTeardown) {
                    [self.dataStore teardownFeedImportContext];
                }
                [op finish];
            });
        }];
    }];
    [self.operationQueue addOperation:op];
}
#endif

- (void)cancelAllFetches {
    [self.operationQueue cancelAllOperations];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if (context == &kvo_WMFExploreFeedContentController_operationQueue_operationCount) {
        if (self.operationQueue.operationCount == 0 && self.isBusy) {
            self.busy = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:WMFExploreFeedContentControllerBusyStateDidChange object:self];
        } else if (self.operationQueue.operationCount > 0 && !self.isBusy) {
            self.busy = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:WMFExploreFeedContentControllerBusyStateDidChange object:self];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
