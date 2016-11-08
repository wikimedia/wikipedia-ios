#import "WMFFeedContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "WMFFeedContentFetcher.h"
#import "WMFContentGroup.h"

#import "WMFFeedDayResponse.h"
#import "WMFFeedArticlePreview.h"
#import "WMFFeedImage.h"
#import "WMFFeedTopReadResponse.h"
#import "WMFFeedNewsStory.h"

#import "WMFArticlePreview.h"
#import "WMFNotificationsController.h"

#import <WMFModel/WMFModel-Swift.h>

@import NSDate_Extensions;

NS_ASSUME_NONNULL_BEGIN

static NSInteger WMFFeedNotificationMinHour = 8;
static NSInteger WMFFeedNotificationMaxHour = 20;
static NSInteger WMFFeedNotificationMaxPerDay = 3;

static NSTimeInterval WMFFeedNotificationArticleRepeatLimit = 30 * 24 * 60 * 60; // 30 days
static NSInteger WMFFeedInTheNewsNotificationMaxRank = 10;
static NSInteger WMFFeedInTheNewsNotificationViewCountDays = 5;

@interface WMFFeedContentSource () <WMFAnalyticsContextProviding>

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;
@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;
@property (readwrite, nonatomic, strong) WMFNotificationsController *notificationsController;

@property (readwrite, nonatomic, strong) WMFFeedContentFetcher *fetcher;

@property (readwrite, getter=isSchedulingNotifications) BOOL schedulingNotifications;

@end

@implementation WMFFeedContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore userDataStore:(MWKDataStore *)userDataStore notificationsController:(nullable WMFNotificationsController *)notificationsController {
    NSParameterAssert(siteURL);
    NSParameterAssert(contentStore);
    NSParameterAssert(previewStore);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.contentStore = contentStore;
        self.previewStore = previewStore;
        self.userDataStore = userDataStore;
        self.notificationsController = notificationsController;
    }
    return self;
}

#pragma mark - Accessors

- (WMFFeedContentFetcher *)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[WMFFeedContentFetcher alloc] init];
    }
    return _fetcher;
}

#pragma mark - WMFContentSource

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    NSDate *date = [NSDate date];
    [self loadContentForDate:date force:force completion:completion];
}

- (void)preloadContentForNumberOfDays:(NSInteger)days force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    if (days < 1) {
        if (completion) {
            completion();
        }
        return;
    }
    
    NSDate *now = [NSDate date];
    
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
 
    WMFTaskGroup *group = [WMFTaskGroup new];
    
    for (NSUInteger i = 0; i < days; i++) {
        [group enter];
        NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:-i toDate:now options:NSCalendarMatchStrictly];
        [self loadContentForDate:date
                           force:force
                      completion:^{
                          [group leave];
                      }];
    }
    
    [group waitInBackgroundWithCompletion:completion];
}

- (void)loadContentForDate:(NSDate *)date force:(BOOL)force completion:(nullable dispatch_block_t)completion {

    [self cleanupBadTopReadSections];

    [self.fetcher fetchFeedContentForURL:self.siteURL
        date:date
        force:force
        failure:^(NSError *_Nonnull error) {
            if (completion) {
                completion();
            }
        }
        success:^(WMFFeedDayResponse *_Nonnull feedDay) {

            NSMutableDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *pageViews = [NSMutableDictionary dictionary];

            NSDate *startDate = [self startDateForPageViewsForDate:date];
            NSDate *endDate = [self endDateForPageViewsForDate:date];

            WMFTaskGroup *group = [WMFTaskGroup new];

            [feedDay.topRead.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedTopReadArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {

                [group enter];
                [self.fetcher fetchPageviewsForURL:obj.articleURL
                    startDate:startDate
                    endDate:endDate
                    failure:^(NSError *_Nonnull error) {
                        [group leave];

                    }
                    success:^(NSDictionary<NSDate *, NSNumber *> *_Nonnull results) {
                        pageViews[obj.articleURL] = results;
                        [group leave];

                    }];
            }];

            [feedDay.newsStories enumerateObjectsUsingBlock:^(WMFFeedNewsStory *_Nonnull newsStory, NSUInteger idx, BOOL *_Nonnull stop) {
                [newsStory.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    [group enter];
                    [self.fetcher fetchPageviewsForURL:obj.articleURL
                        startDate:startDate
                        endDate:endDate
                        failure:^(NSError *_Nonnull error) {
                            [group leave];
                        }
                        success:^(NSDictionary<NSDate *, NSNumber *> *_Nonnull results) {
                            pageViews[obj.articleURL] = results;
                            [group leave];
                        }];
                }];
            }];

            [group waitInBackgroundWithCompletion:^{

                [self saveContentForFeedDay:feedDay pageViews:pageViews onDate:date completion:completion];
            }];
        }];
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:[WMFFeaturedArticleContentGroup kind]];
    [self.contentStore removeAllContentGroupsOfKind:[WMFPictureOfTheDayContentGroup kind]];
    [self.contentStore removeAllContentGroupsOfKind:[WMFTopReadContentGroup kind]];
    [self.contentStore removeAllContentGroupsOfKind:[WMFNewsContentGroup kind]];
}

- (void)cleanupBadTopReadSections {
    NSMutableArray *remove = [NSMutableArray array];
    [self.contentStore enumerateContentGroupsOfKind:[WMFTopReadContentGroup kind]
                                          withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                              if (![group isKindOfClass:[WMFTopReadContentGroup class]]) {
                                                  return;
                                              }
                                              WMFTopReadContentGroup *tg = (WMFTopReadContentGroup *)group;
                                              if (tg.date == nil || tg.mostReadDate == nil) {
                                                  [remove addObject:[tg databaseKey]];
                                              }
                                          }];
    [self.contentStore removeContentGroupsWithKeys:remove];
}

#pragma mark - Save Groups

- (void)saveContentForFeedDay:(WMFFeedDayResponse *)feedDay pageViews:(NSMutableDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews onDate:(NSDate *)date completion:(dispatch_block_t)completion {
    [self saveGroupForFeaturedPreview:feedDay.featuredArticle date:date];
    [self saveGroupForTopRead:feedDay.topRead pageViews:pageViews date:date];
    [self saveGroupForPictureOfTheDay:feedDay.pictureOfTheDay date:date];
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
    if ([calendar isDateInToday:date]) {
        [self saveGroupForNews:feedDay.newsStories pageViews:pageViews date:date];
    }
    [self.contentStore notifyWhenWriteTransactionsComplete:^{
        [self.previewStore notifyWhenWriteTransactionsComplete:^{
            [self scheduleNotificationsForFeedDay:feedDay onDate:date];
            if (!completion) {
                return;
            }
            completion();
        }];
    }];
}

- (void)saveGroupForFeaturedPreview:(WMFFeedArticlePreview *)preview date:(NSDate *)date {
    if (!preview || !date) {
        return;
    }

    WMFFeaturedArticleContentGroup *featured = [self featuredForDate:date];

    if (featured == nil) {
        featured = [[WMFFeaturedArticleContentGroup alloc] initWithDate:date siteURL:self.siteURL];
    }

    NSURL *featuredURL = [preview articleURL];

    if (!featuredURL) {
        return;
    }

    [self.previewStore addPreviewWithURL:featuredURL updatedWithFeedPreview:preview pageViews:nil];
    [self.contentStore addContentGroup:featured associatedContent:@[featuredURL]];
}

- (void)saveGroupForTopRead:(WMFFeedTopReadResponse *)topRead pageViews:(NSMutableDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews date:(NSDate *)date {
    //Sometimes top read is nil, depends on time of day
    if ([topRead.articlePreviews count] == 0 || date == nil) {
        return;
    }

    WMFTopReadContentGroup *group = [self topReadForDate:date];

    if (group == nil) {
        group = [[WMFTopReadContentGroup alloc] initWithDate:date mostReadDate:topRead.date siteURL:self.siteURL];
    }

    [topRead.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedTopReadArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSURL *url = [obj articleURL];
        [self.previewStore addPreviewWithURL:url updatedWithFeedPreview:obj pageViews:pageViews[url]];
    }];

    [self.contentStore addContentGroup:group associatedContent:topRead.articlePreviews];
}

- (void)saveGroupForPictureOfTheDay:(WMFFeedImage *)image date:(NSDate *)date {
    if (image == nil || date == nil) {
        return;
    }

    WMFPictureOfTheDayContentGroup *group = [self pictureOfTheDayForDate:date];

    if (group == nil) {
        group = [[WMFPictureOfTheDayContentGroup alloc] initWithDate:date siteURL:self.siteURL];
    }

    [self.contentStore addContentGroup:group associatedContent:@[image]];
}

- (void)saveGroupForNews:(NSArray<WMFFeedNewsStory *> *)news pageViews:(NSMutableDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews date:(NSDate *)date {
    if ([news count] == 0 || date == nil) {
        return;
    }

    WMFNewsContentGroup *group = [self newsForDate:date];

    if (group == nil) {
        group = [[WMFNewsContentGroup alloc] initWithDate:date siteURL:self.siteURL];
    }

    [news enumerateObjectsUsingBlock:^(WMFFeedNewsStory *_Nonnull story, NSUInteger idx, BOOL *_Nonnull stop) {
        __block unsigned long long mostViews = 0;
        __block WMFFeedArticlePreview *mostViewedPreview = nil;
        __block WMFFeedArticlePreview *semanticFeaturedPreview = nil;

        NSString *featuredArticleTitleBasedOnSemanticLookup = [WMFFeedNewsStory semanticFeaturedArticleTitleFromStoryHTML:story.storyHTML];
        if (featuredArticleTitleBasedOnSemanticLookup) {
            NSURL *featuredArticleURL = [NSURL wmf_URLWithSiteURL:self.siteURL title:featuredArticleTitleBasedOnSemanticLookup fragment:nil];
            NSString *featuredArticleDabaseKey = [featuredArticleURL wmf_articleDatabaseKey];
            [story.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                NSURL *url = [obj articleURL];
                if (featuredArticleDabaseKey && [[url wmf_articleDatabaseKey] isEqualToString:featuredArticleDabaseKey]) {
                    semanticFeaturedPreview = obj;
                }
                NSDictionary<NSDate *, NSNumber *> *pageViewsForURL = pageViews[url];
                NSArray *dates = [pageViewsForURL.allKeys sortedArrayUsingSelector:@selector(compare:)];
                NSDate *latestDate = [dates lastObject];
                if (latestDate) {
                    NSNumber *pageViewsNumber = pageViewsForURL[latestDate];
                    unsigned long long views = [pageViewsNumber unsignedLongLongValue];
                    if (views > mostViews) {
                        mostViews = views;
                        mostViewedPreview = obj;
                    }
                }
                [self.previewStore addPreviewWithURL:url updatedWithFeedPreview:obj pageViews:pageViewsForURL];
            }];
            story.featuredArticlePreview = semanticFeaturedPreview ? semanticFeaturedPreview : mostViewedPreview;
        } else {
            story.featuredArticlePreview = [[story articlePreviews] firstObject];
        }

    }];

    [self.contentStore addContentGroup:group associatedContent:news];
}

#pragma mark - Find Groups

- (nullable WMFFeaturedArticleContentGroup *)featuredForDate:(NSDate *)date {

    return (id)[self.contentStore firstGroupOfKind:[WMFFeaturedArticleContentGroup kind] forDate:date];
}

- (nullable WMFPictureOfTheDayContentGroup *)pictureOfTheDayForDate:(NSDate *)date {
    return (id)[self.contentStore firstGroupOfKind:[WMFPictureOfTheDayContentGroup kind] forDate:date];
}

- (nullable WMFTopReadContentGroup *)topReadForDate:(NSDate *)date {
    return (id)[self.contentStore firstGroupOfKind:[WMFTopReadContentGroup kind] forDate:date];
}

- (nullable WMFNewsContentGroup *)newsForDate:(NSDate *)date {
    return (id)[self.contentStore firstGroupOfKind:[WMFNewsContentGroup kind] forDate:date];
}

#pragma mark - Notifications

- (void)scheduleNotificationsForFeedDay:(WMFFeedDayResponse *)feedDay onDate:(NSDate *)date {
    if (![[NSUserDefaults wmf_userDefaults] wmf_inTheNewsNotificationsEnabled]) {
        return;
    }

    if (self.isSchedulingNotifications) {
        return;
    }

    NSCalendar *userCalendar = [NSCalendar wmf_gregorianCalendar];
    if (![userCalendar isDateInToday:date]) { //in the news notifications only valid for the current day
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    NSDate *mostRecentDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
    BOOL ignoreTopReadRequirement = !mostRecentDate || ([userCalendar daysFromDate:mostRecentDate toDate:[NSDate date]] >= 3);

    self.schedulingNotifications = YES;

    NSArray<WMFFeedTopReadArticlePreview *> *articlePreviews = feedDay.topRead.articlePreviews;
    NSMutableDictionary<NSString *, WMFFeedTopReadArticlePreview *> *topReadArticlesByKey = [NSMutableDictionary dictionaryWithCapacity:articlePreviews.count];
    for (WMFFeedTopReadArticlePreview *articlePreview in articlePreviews) {
        NSString *key = articlePreview.articleURL.wmf_articleDatabaseKey;
        if (!key) {
            continue;
        }
        topReadArticlesByKey[key] = articlePreview;
    }

    for (WMFFeedNewsStory *newsStory in feedDay.newsStories) {
        WMFArticlePreview *articlePreviewToNotifyAbout = nil;
        NSInteger bestRank = NSIntegerMax;
        NSMutableArray<NSURL *> *articleURLs = [NSMutableArray arrayWithCapacity:newsStory.articlePreviews.count];
        for (WMFFeedArticlePreview *articlePreview in newsStory.articlePreviews) {
            NSURL *articleURL = articlePreview.articleURL;
            if (!articleURL) {
                continue;
            }
            NSString *key = articleURL.wmf_articleDatabaseKey;
            if (!key) {
                continue;
            }
            [articleURLs addObject:articleURL];
            WMFFeedTopReadArticlePreview *topReadArticlePreview = topReadArticlesByKey[key];
            if ((ignoreTopReadRequirement || topReadArticlePreview) && topReadArticlePreview.rank.integerValue < WMFFeedInTheNewsNotificationMaxRank) {
                MWKHistoryEntry *entry = [self.userDataStore entryForURL:articlePreview.articleURL];
                BOOL notifiedRecently = entry.inTheNewsNotificationDate && [entry.inTheNewsNotificationDate timeIntervalSinceNow] < WMFFeedNotificationArticleRepeatLimit;
                BOOL viewedRecently = entry.dateViewed && [entry.dateViewed timeIntervalSinceNow] < WMFFeedNotificationArticleRepeatLimit;
                if (notifiedRecently || viewedRecently) {
                    articlePreviewToNotifyAbout = nil;
                    break;
                }

                if (!articlePreviewToNotifyAbout || (topReadArticlePreview && topReadArticlePreview.rank.integerValue < bestRank)) {
                    bestRank = topReadArticlePreview ? topReadArticlePreview.rank.integerValue : NSIntegerMax;
                    articlePreviewToNotifyAbout = [self.previewStore itemForURL:articleURL];
                }
            }
        }
        if (articlePreviewToNotifyAbout && articlePreviewToNotifyAbout.url) {
            if ([self scheduleNotificationForNewsStory:newsStory articlePreview:articlePreviewToNotifyAbout force:NO]) {

                [[PiwikTracker sharedInstance] wmf_logActionPushInContext:self contentType:articlePreviewToNotifyAbout.url.host date:[NSDate date]];
            };
            break;
        }
    }
    self.schedulingNotifications = NO;
}

- (BOOL)scheduleNotificationForNewsStory:(WMFFeedNewsStory *)newsStory
                          articlePreview:(WMFArticlePreview *)articlePreview
                                   force:(BOOL)force {
    if (!newsStory.featuredArticlePreview) {
        NSString *articlePreviewKey = articlePreview.url.wmf_articleDatabaseKey;
        if (!articlePreviewKey) {
            return NO;
        }
        for (WMFFeedArticlePreview *preview in newsStory.articlePreviews) {
            if ([preview.articleURL.wmf_articleDatabaseKey isEqualToString:articlePreviewKey]) {
                newsStory.featuredArticlePreview = preview;
                break;
            } else {
                newsStory.featuredArticlePreview = preview;
            }
        }
        if (!newsStory.featuredArticlePreview) {
            return NO;
        }
    }

    NSError *JSONError = nil;
    NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:newsStory error:&JSONError];
    if (JSONError) {
        DDLogError(@"Error serializing news story: %@", JSONError);
    }

    NSString *articleURLString = articlePreview.url.absoluteString;
    NSString *storyHTML = newsStory.storyHTML;
    NSString *displayTitle = articlePreview.displayTitle;
    NSDictionary *viewCounts = articlePreview.pageViews;

    if (!storyHTML || !articleURLString || !displayTitle || !JSONDictionary) {
        return NO;
    }

    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:4];
    info[WMFNotificationInfoArticleTitleKey] = displayTitle;
    info[WMFNotificationInfoViewCountsKey] = viewCounts;
    info[WMFNotificationInfoArticleURLStringKey] = articleURLString;
    info[WMFNotificationInfoFeedNewsStoryKey] = JSONDictionary;
    NSString *thumbnailURLString = articlePreview.thumbnailURL.absoluteString;
    if (thumbnailURLString) {
        info[WMFNotificationInfoThumbnailURLStringKey] = thumbnailURLString;
    }
    NSString *snippet = articlePreview.wikidataDescription ?: articlePreview.snippet;
    if (snippet) {
        info[WMFNotificationInfoArticleExtractKey] = snippet;
    }

    NSString *title = NSLocalizedString(@"in-the-news-title", nil);
    NSString *body = [storyHTML wmf_stringByRemovingHTML];

    NSDate *notificationDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *notificationDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:notificationDate];

    if (force) {
        // nil the components to indicate it should be sent immediately, date should still be [NSDate date]
        notificationDateComponents = nil;
    } else {
        if (notificationDateComponents.hour < WMFFeedNotificationMinHour) {
            notificationDateComponents.hour = WMFFeedNotificationMinHour;
            notificationDateComponents.minute = 1;
            notificationDate = [calendar dateFromComponents:notificationDateComponents];
        } else if (notificationDateComponents.hour > WMFFeedNotificationMaxHour) {
            // Send it tomorrow
            notificationDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:notificationDate options:NSCalendarMatchStrictly];
            notificationDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:notificationDate];
            notificationDateComponents.hour = WMFFeedNotificationMinHour;
            notificationDateComponents.minute = 1;
            notificationDate = [calendar dateFromComponents:notificationDateComponents];
        } else {
            // nil the components to indicate it should be sent immediately, date should still be [NSDate date]
            notificationDateComponents = nil;
        }
        NSCalendar *userCalendar = [NSCalendar autoupdatingCurrentCalendar];
        NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
        NSDate *mostRecentDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
        if ([userCalendar daysFromDate:notificationDate toDate:mostRecentDate] > 0) { // don't send if we have a notification scheduled for tomorrow already
            return NO;
        }
        if (mostRecentDate && [userCalendar isDate:mostRecentDate inSameDayAsDate:notificationDate]) {
            NSInteger count = [defaults wmf_inTheNewsMostRecentDateNotificationCount];
            if (count >= WMFFeedNotificationMaxPerDay) {
                return NO;
            }
        }
    }

    [self.notificationsController sendNotificationWithTitle:title body:body categoryIdentifier:WMFInTheNewsNotificationCategoryIdentifier userInfo:info atDateComponents:notificationDateComponents];
    NSArray<NSURL *> *articleURLs = [newsStory.articlePreviews wmf_mapAndRejectNil:^NSURL *_Nullable(WMFFeedArticlePreview *_Nonnull obj) {
        return obj.articleURL;
    }];

    [self.userDataStore.historyList setInTheNewsNotificationDate:notificationDate forArticlesWithURLs:articleURLs];

    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    NSDate *mostRecentDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
    if (mostRecentDate && [calendar isDateInToday:mostRecentDate]) {
        NSInteger count = [defaults wmf_inTheNewsMostRecentDateNotificationCount] + 1;
        [defaults wmf_setInTheNewsMostRecentDateNotificationCount:count];
    } else {
        [defaults wmf_setMostRecentInTheNewsNotificationDate:notificationDate];
        [defaults wmf_setInTheNewsMostRecentDateNotificationCount:1];
    }

    return YES;
}

- (NSString *)analyticsContext {
    return @"notification";
}

#pragma mark - Utility

- (NSDate *)startDateForPageViewsForDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    NSDate *dateUTC = [calendar dateFromComponents:dateComponents];
    NSDate *startDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:0 - WMFFeedInTheNewsNotificationViewCountDays toDate:dateUTC options:NSCalendarMatchStrictly];
    return startDate;
}

- (NSDate *)endDateForPageViewsForDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    NSDate *dateUTC = [calendar dateFromComponents:dateComponents];
    return dateUTC;
}

- (void)clearCache:(nonnull dispatch_block_t)completion {
    [self.fetcher clearCache:completion];
}
@end

NS_ASSUME_NONNULL_END
