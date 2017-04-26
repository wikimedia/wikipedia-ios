#import "WMFExploreFeedContentController.h"
#import "WMFRelatedPagesContentSource.h"
#import "WMFMainPageContentSource.h"
#import "WMFNearbyContentSource.h"
#import "WMFContinueReadingContentSource.h"
#import "WMFFeedContentSource.h"
#import "WMFRandomContentSource.h"
#import "WMFAnnouncementsContentSource.h"
#import "WMFAssertions.h"
#import <WMF/WMF-Swift.h>

static const NSTimeInterval WMFFeedRefreshTimeoutInterval = 12;
static NSTimeInterval WMFFeedRefreshBackgroundTimeout = 30;

@interface WMFExploreFeedContentController ()

@property (nonatomic, strong) NSArray<id<WMFContentSource>> *contentSources;
@property (nonatomic, strong) WMFTaskGroup *taskGroup;
@property (nonatomic, strong) NSMutableArray <dispatch_block_t>*queue;
@end

@implementation WMFExploreFeedContentController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.queue = [NSMutableArray arrayWithCapacity:1];
    }
    return self;
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
    NSParameterAssert([self siteURL]);
    if (!_contentSources) {
        WMFFeedContentSource *feedContentSource = [[WMFFeedContentSource alloc] initWithSiteURL:[self siteURL]
                                                                                  userDataStore:self.dataStore
                                                                        notificationsController:[WMFNotificationsController sharedNotificationsController]];
        feedContentSource.notificationSchedulingEnabled = YES;
        _contentSources = @[
                            [[WMFRelatedPagesContentSource alloc] init],
                            [[WMFMainPageContentSource alloc] initWithSiteURL:[self siteURL]],
                            [[WMFContinueReadingContentSource alloc] initWithUserDataStore:self.dataStore],
                            [[WMFNearbyContentSource alloc] initWithSiteURL:[self siteURL] dataStore:self.dataStore],
                            feedContentSource,
                            [[WMFRandomContentSource alloc] initWithSiteURL:[self siteURL]],
                            [[WMFAnnouncementsContentSource alloc] initWithSiteURL:[self siteURL]]
                            ];
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
    if (self.taskGroup) {
        @weakify(self);
        [self.queue addObject:^{
            @strongify(self);
            [self updateFeedSourcesWithDate:date userInitiated:wasUserInitiated completion:completion];
        }];
        return;
    }
    
    WMFTaskGroup *group = [WMFTaskGroup new];
    self.taskGroup = group;
#if DEBUG
    NSMutableSet *entered = [NSMutableSet setWithCapacity:self.contentSources.count];
#endif
    NSManagedObjectContext *moc = self.dataStore.feedImportContext;
    [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [group enter];
#if DEBUG
        NSString *classString = NSStringFromClass([obj class]);
        [entered addObject:classString];
#endif
        dispatch_block_t contentSourceCompletion = ^{
#if DEBUG
            assert([entered containsObject:classString]);
            [entered removeObject:classString];
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
                                    if ([moc hasChanges] && ![moc save:&saveError]) {
                                        DDLogError(@"Error saving: %@", saveError);
                                    }
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self.dataStore teardownFeedImportContext];
                                        [[NSUserDefaults wmf_userDefaults] wmf_setFeedRefreshDate:[NSDate date]];
                                        self.taskGroup = nil;
                                        if (completion) {
                                            completion();
                                        }
                                        [self popQueue];
                                    });
                                }];
                                
#if DEBUG
                                if ([entered count] > 0) {
                                    DDLogError(@"Didn't leave: %@", entered);
                                }
#endif
                            }];
}

- (void)updateNearbyForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    WMFAssertMainThread(@"updateNearby: must be called on the main thread");
    if (self.taskGroup) {
        @weakify(self);
        [self.queue addObject:^{
            @strongify(self);
            [self updateNearbyForce:force completion:completion];
        }];
        return;
    }
    NSManagedObjectContext *moc = self.dataStore.viewContext;
    WMFTaskGroup *group = [WMFTaskGroup new];
    self.taskGroup = group;
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
                                        self.taskGroup = nil;
                                        if (completion) {
                                            completion();
                                        }
                                        [self popQueue];
                                    });
                                }];
                            }];
}

- (void)updateBackgroundSourcesWithCompletion:(void (^_Nonnull)(UIBackgroundFetchResult))completionHandler {
    WMFAssertMainThread(@"updateBackgroundSourcesWithCompletion: must be called on the main thread");
    if (self.taskGroup) {
        @weakify(self);
        [self.queue addObject:^{
            @strongify(self);
            [self updateBackgroundSourcesWithCompletion:completionHandler];
        }];
        return;
    }
    WMFTaskGroup *group = [WMFTaskGroup new];
    self.taskGroup = group;
    NSManagedObjectContext *moc = self.dataStore.viewContext;
    NSFetchRequest *beforeFetchRequest = [WMFContentGroup fetchRequest];
    NSInteger beforeCount = [moc countForFetchRequest:beforeFetchRequest error:nil];
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
    
    [group waitInBackgroundWithTimeout:WMFFeedRefreshBackgroundTimeout completion:^{
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
                self.taskGroup = nil;
                [self popQueue];
            });
        }];
    }];
}

#pragma mark - Queue

- (void)popQueue {
    WMFAssertMainThread(@"popQueue: must be called on the main thread");
    dispatch_block_t queued = [self.queue firstObject];
    if (!queued) {
        return;
    }
    
    [self.queue removeObjectAtIndex:0];
    
    queued();
}

#pragma mark - SiteURL 

- (void)setSiteURL:(NSURL *)siteURL {
    _siteURL = [siteURL copy];
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
    if (self.taskGroup) {
        return;
    }
    self.taskGroup = [WMFTaskGroup new];
    BOOL needsTeardown = arc4random_uniform(2) > 0;
    NSManagedObjectContext *moc = needsTeardown ? self.dataStore.feedImportContext : self.dataStore.viewContext;
    [moc performBlock:^{
        NSFetchRequest *request = [WMFContentGroup fetchRequest];
        NSInteger count = [moc countForFetchRequest:request error:nil];
        request.fetchLimit = (NSUInteger) arc4random_uniform((uint32_t)3);
        request.fetchOffset = (NSUInteger) arc4random_uniform((uint32_t)(count - request.fetchLimit));
        NSArray *results = [moc executeFetchRequest:request error:nil];
        NSDate *now = [NSDate date];
        for (WMFContentGroup *group in results) {
            uint32_t seed = arc4random_uniform(5);
            NSTimeInterval timeInterval = [now timeIntervalSinceDate:group.date];
            NSTimeInterval adjustment = (timeInterval - 2*arc4random_uniform((uint32_t)timeInterval));
            NSTimeInterval originalDelta = [group.contentMidnightUTCDate timeIntervalSinceDate:group.midnightUTCDate];
            switch (seed) {
                case 0:
                case 1:
                {
                    group.date = [group.date dateByAddingTimeInterval:adjustment];
                    group.midnightUTCDate = [group.date wmf_midnightUTCDateFromLocalDate];
                    group.contentMidnightUTCDate = [group.midnightUTCDate dateByAddingTimeInterval:originalDelta];

                }
                    break;
                case 2:
                    [moc deleteObject:group];
                default:
                {
                    [moc createGroupOfKind:group.contentGroupKind forDate:[group.date dateByAddingTimeInterval:adjustment] withSiteURL:group.siteURL associatedContent:group.content customizationBlock:^(WMFContentGroup * _Nonnull newGroup) {
                        newGroup.articleURLString = group.articleURLString;
                        newGroup.location = group.location;
                        newGroup.placemark = group.placemark;
                        newGroup.contentMidnightUTCDate = [newGroup.midnightUTCDate dateByAddingTimeInterval:originalDelta];
                    }];
                }
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
            self.taskGroup = nil;
            [self popQueue];
        });
    }];
}
#endif
@end
