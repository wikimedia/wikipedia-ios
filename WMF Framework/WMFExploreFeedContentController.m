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

NSString * const WMFExploreFeedContentControllerBusyStateDidChange = @"WMFExploreFeedContentControllerBusyStateDidChange";

static const NSTimeInterval WMFFeedRefreshTimeoutInterval = 12;
static NSTimeInterval WMFFeedRefreshBackgroundTimeout = 30;
static const NSString *kvo_WMFExploreFeedContentController_operationQueue_operationCount = @"kvo_WMFExploreFeedContentController_operationQueue_operationCount";

@interface WMFExploreFeedContentController ()

@property (nonatomic, strong) NSArray<id<WMFContentSource>> *contentSources;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation WMFExploreFeedContentController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)dealloc {
    self.operationQueue = nil;
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
    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation * _Nonnull op){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSManagedObjectContext *moc = self.dataStore.feedImportContext;
            WMFTaskGroup *group = [WMFTaskGroup new];
#if DEBUG
            NSMutableSet *entered = [NSMutableSet setWithCapacity:self.contentSources.count];
#endif
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
    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation * _Nonnull op){
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
    
    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation * _Nonnull op) {
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
                    [op finish];
                });
            }];
        }];
    }];
    [self.operationQueue addOperation:op];
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
    WMFAsyncBlockOperation *op = [[WMFAsyncBlockOperation alloc] initWithAsyncBlock:^(WMFAsyncBlockOperation * _Nonnull op) {
        BOOL needsTeardown = arc4random_uniform(2) > 0;
        NSManagedObjectContext *moc = needsTeardown ? self.dataStore.feedImportContext : self.dataStore.viewContext;
        [moc performBlock:^{
            NSFetchRequest *request = [WMFContentGroup fetchRequest];
            NSInteger count = [moc countForFetchRequest:request error:nil];
            request.fetchLimit = (NSUInteger) arc4random_uniform((uint32_t)count);
            request.fetchOffset = (NSUInteger) arc4random_uniform((uint32_t)(count - request.fetchLimit));
            NSArray *results = [moc executeFetchRequest:request error:nil];
            for (WMFContentGroup *group in results) {
                uint32_t seed = arc4random_uniform(5);
                int32_t random = (15 - (int32_t)arc4random_uniform(30));
                switch (seed) {
                    case 0:
                        group.dailySortPriority = group.dailySortPriority + random;
                        break;
                    case 1:
                        group.midnightUTCDate = [group.midnightUTCDate dateByAddingTimeInterval:86400*random];
                        group.contentMidnightUTCDate = [group.contentMidnightUTCDate dateByAddingTimeInterval:86400*random];
                        group.date = [group.date dateByAddingTimeInterval:86400*random];
                        break;
                    case 2:
                        [moc deleteObject:group];
                    default:
                    {
                        [moc createGroupOfKind:group.contentGroupKind forDate:[group.date dateByAddingTimeInterval:86400*random] withSiteURL:group.siteURL associatedContent:group.content customizationBlock:^(WMFContentGroup * _Nonnull newGroup) {
                            newGroup.location = group.location;
                            newGroup.placemark = group.placemark;
                            newGroup.contentMidnightUTCDate = [group.contentMidnightUTCDate dateByAddingTimeInterval:86400*random];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
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


