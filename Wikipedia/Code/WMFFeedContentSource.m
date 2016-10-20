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

#define WMF_ALWAYS_LOAD_FEED_DATA DEBUG && 0
#define WMF_ALWAYS_NOTIFY DEBUG && 0

@import NSDate_Extensions;

NS_ASSUME_NONNULL_BEGIN

static NSInteger WMFFeedNotificationMinHour = 8;
static NSInteger WMFFeedNotificationMaxHour = 20;
static NSInteger WMFFeedNotificationMaxPerDay = 3;

static NSTimeInterval WMFFeedNotificationArticleRepeatLimit = 30 * 24 * 60 * 60; // 30 days
static NSInteger WMFFeedInTheNewsNotificationMaxRank = 10;
static NSInteger WMFFeedInTheNewsNotificationViewCountDays = 5;

@interface WMFFeedContentSource ()

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
        self.updateInterval = 30 * 60;
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
    [self loadContentForDate:[NSDate date] completion:completion];
}

- (void)loadContentFromDate:(NSDate *)fromDate forwardForDays:(NSInteger)days completion:(nullable dispatch_block_t)completion {
    if (days <= 0) {
        if (completion) {
            completion();
        }
        return;
    }
    [self loadContentForDate:fromDate
                  completion:^{
                      NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
                      NSDate *updatedFromDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:fromDate options:NSCalendarMatchStrictly];
                      [self loadContentFromDate:updatedFromDate forwardForDays:days - 1 completion:completion];
                  }];
}

- (void)preloadContentForNumberOfDays:(NSInteger)days completion:(nullable dispatch_block_t)completion {
    NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
    NSDate *fromDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:-days toDate:[NSDate date] options:NSCalendarMatchStrictly];
    [self loadContentFromDate:fromDate forwardForDays:days completion:completion];
}

- (void)loadContentForDate:(NSDate *)date completion:(nullable dispatch_block_t)completion {

#if WMF_ALWAYS_LOAD_FEED_DATA
#else
    WMFTopReadContentGroup *topRead = [self topReadForDate:date];

    //TODO: check which languages support most read???
    if (topRead != nil) {
        //Safe to assume we have everything since Top Read comes in last
        if (completion) {
            completion();
        }
        return;
    }
#endif

    [self.fetcher fetchFeedContentForURL:self.siteURL
        date:date
        failure:^(NSError *_Nonnull error) {
            if (completion) {
                completion();
            }

        }
        success:^(WMFFeedDayResponse *_Nonnull feedDay) {

            NSMutableDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *pageViews = [NSMutableDictionary dictionary];

            NSDate *startDate = [self startDateForPageViewsForDate:date];
            NSDate *endDate = [self endDateForPreviewsForDate:date];

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
            
            [feedDay.newsStories enumerateObjectsUsingBlock:^(WMFFeedNewsStory * _Nonnull newsStory, NSUInteger idx, BOOL * _Nonnull stop) {
                [newsStory.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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

#pragma mark - Save Groups

- (void)saveContentForFeedDay:(WMFFeedDayResponse *)feedDay pageViews:(NSMutableDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews onDate:(NSDate *)date completion:(dispatch_block_t)completion {
    [self saveGroupForFeaturedPreview:feedDay.featuredArticle date:date];
    [self saveGroupForTopRead:feedDay.topRead pageViews:pageViews date:date];
    [self saveGroupForPictureOfTheDay:feedDay.pictureOfTheDay date:date];
    if ([date wmf_isTodayUTC]) {
        [self saveGroupForNews:feedDay.newsStories pageViews:pageViews date:date];
    }
    [self scheduleNotificationsForFeedDay:feedDay onDate:date];

    [self.contentStore notifyWhenWriteTransactionsComplete:completion];
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

    WMFPictureOfTheDayContentGroup *group = [self pictureOfTheDayForDate:date];

    if (group == nil) {
        group = [[WMFPictureOfTheDayContentGroup alloc] initWithDate:date siteURL:self.siteURL];
    }

    [self.contentStore addContentGroup:group associatedContent:@[image]];
}

- (void)saveGroupForNews:(NSArray<WMFFeedNewsStory *> *)news pageViews:(NSMutableDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews date:(NSDate *)date {

    WMFNewsContentGroup *group = [self newsForDate:date];

    if (group == nil) {
        group = [[WMFNewsContentGroup alloc] initWithDate:date siteURL:self.siteURL];
    }

    [news enumerateObjectsUsingBlock:^(WMFFeedNewsStory *_Nonnull story, NSUInteger idx, BOOL *_Nonnull stop) {
        __block unsigned long long mostViews = 0;
        __block WMFFeedArticlePreview *mostViewedPreview = nil;
        [story.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            NSURL *url = [obj articleURL];
            NSDictionary *pageViewsForURL = pageViews[url];
            NSArray *dates = [pageViewsForURL.allKeys sortedArrayUsingSelector:@selector(compare:)];
            NSArray *latestDate = [dates lastObject];
            if (latestDate) {
                unsigned long long views = [pageViewsForURL[latestDate] unsignedLongLongValue];
                if (views > mostViews) {
                    mostViews = views;
                    mostViewedPreview = obj;
                }
            }
            [self.previewStore addPreviewWithURL:url updatedWithFeedPreview:obj pageViews:pageViewsForURL];
        }];
        story.mostPopularArticlePreview = mostViewedPreview;
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
    if (self.isSchedulingNotifications) {
        return;
    }

    self.schedulingNotifications = YES;

    if (![date wmf_isTodayUTC]) { //in the news notifications only valid for the current day
        return;
    }

    NSCalendar *userCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    NSDate *mostRecentDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
    if ([userCalendar isDateInToday:mostRecentDate]) {
        NSInteger count = [defaults wmf_inTheNewsMostRecentDateNotificationCount];
        if (count >= WMFFeedNotificationMaxPerDay) {
            return;
        }
    }

    NSArray<WMFFeedTopReadArticlePreview *> *articlePreviews = feedDay.topRead.articlePreviews;
    NSMutableDictionary<NSString *, WMFFeedTopReadArticlePreview *> *topReadArticlesByKey = [NSMutableDictionary dictionaryWithCapacity:articlePreviews.count];
    for (WMFFeedTopReadArticlePreview *articlePreview in articlePreviews) {
        NSString *key = articlePreview.articleURL.wmf_databaseKey;
        if (!key) {
            continue;
        }
        topReadArticlesByKey[key] = articlePreview;
    }

    for (WMFFeedNewsStory *newsStory in feedDay.newsStories) {
        WMFArticlePreview *articlePreviewToNotifyAbout = nil;
#if WMF_ALWAYS_NOTIFY
#else
        NSInteger bestRank = NSIntegerMax;
#endif

        NSMutableArray<NSURL *> *articleURLs = [NSMutableArray arrayWithCapacity:newsStory.articlePreviews.count];
        for (WMFFeedArticlePreview *articlePreview in newsStory.articlePreviews) {
            NSURL *articleURL = articlePreview.articleURL;
            if (!articleURL) {
                continue;
            }
            NSString *key = articleURL.wmf_databaseKey;
            if (!key) {
                continue;
            }
            [articleURLs addObject:articleURL];
#if WMF_ALWAYS_NOTIFY
            if (YES) {
#else
            WMFFeedTopReadArticlePreview *topReadArticlePreview = topReadArticlesByKey[key];
            if (topReadArticlePreview && topReadArticlePreview.rank.integerValue < WMFFeedInTheNewsNotificationMaxRank) {
#endif
#if WMF_ALWAYS_NOTIFY
                articlePreviewToNotifyAbout = [self.previewStore itemForURL:articleURL];
#else
                MWKHistoryEntry *entry = [self.userDataStore entryForURL:articlePreview.articleURL];
                BOOL notifiedRecently = entry.inTheNewsNotificationDate && [entry.inTheNewsNotificationDate timeIntervalSinceNow] < WMFFeedNotificationArticleRepeatLimit;
                BOOL viewedRecently = entry.dateViewed && [entry.dateViewed timeIntervalSinceNow] < WMFFeedNotificationArticleRepeatLimit;
                if (notifiedRecently || viewedRecently) {
                    articlePreviewToNotifyAbout = nil;
                    break;
                }

                if (!articlePreviewToNotifyAbout || topReadArticlePreview.rank.integerValue < bestRank) {
                    bestRank = topReadArticlePreview.rank.integerValue;
                    articlePreviewToNotifyAbout = [self.previewStore itemForURL:articleURL];
                }
#endif
            }
        }
        if (articlePreviewToNotifyAbout && articlePreviewToNotifyAbout.url) {
            [self scheduleNotificationForNewsStory:newsStory articlePreview:articlePreviewToNotifyAbout];
            break;
        }
    }
    self.schedulingNotifications = NO;
}

- (BOOL)scheduleNotificationForNewsStory:(WMFFeedNewsStory *)newsStory articlePreview:(WMFArticlePreview *)articlePreview {
    NSString *articleURLString = articlePreview.url.absoluteString;
    NSString *storyHTML = newsStory.storyHTML;
    NSString *displayTitle = articlePreview.displayTitle;
    NSDictionary *viewCounts = articlePreview.pageViews;

    if (!storyHTML || !articleURLString || !displayTitle) {
        return NO;
    }

    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:4];
    info[WMFNotificationInfoStoryHTMLKey] = storyHTML;
    info[WMFNotificationInfoArticleTitleKey] = displayTitle;
    info[WMFNotificationInfoViewCountsKey] = viewCounts;
    info[WMFNotificationInfoArticleURLStringKey] = articleURLString;
    NSString *thumbnailURLString = articlePreview.thumbnailURL.absoluteString;
    if (thumbnailURLString) {
        info[WMFNotificationInfoThumbnailURLStringKey] = thumbnailURLString;
    }
    NSString *snippet = articlePreview.snippet ?: articlePreview.wikidataDescription;
    if (snippet) {
        info[WMFNotificationInfoArticleExtractKey] = snippet;
    }

    NSString *title = NSLocalizedString(@"in-the-news-title", nil);
    NSString *body = [storyHTML wmf_stringByRemovingHTML];

    NSDate *notificationDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *notificationDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:notificationDate];
    if (notificationDateComponents.hour < WMFFeedNotificationMinHour || notificationDateComponents.hour > WMFFeedNotificationMaxHour) {
        // Send it tomorrow
        notificationDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:notificationDate options:NSCalendarMatchStrictly];
        notificationDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:notificationDate];
        notificationDateComponents.hour = WMFFeedNotificationMinHour;
        notificationDateComponents.minute = 1;
        notificationDate = [calendar dateFromComponents:notificationDateComponents];
    } else {
        // Only nil the components to indicate it should be sent immediately, date should still be [NSDate date]
        notificationDateComponents = nil;
    }

    [self.notificationsController sendNotificationWithTitle:title body:body categoryIdentifier:WMFInTheNewsNotificationCategoryIdentifier userInfo:info atDateComponents:notificationDateComponents];
    NSArray<NSURL *> *articleURLs = [newsStory.articlePreviews wmf_mapAndRejectNil:^NSURL *_Nullable(WMFFeedArticlePreview *_Nonnull obj) {
        return obj.articleURL;
    }];

    [self.userDataStore.historyList setInTheNewsNotificationDate:notificationDate forArticlesWithURLs:articleURLs];

    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    NSDate *mostRecentDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
    if ([calendar isDateInToday:mostRecentDate]) {
        NSInteger count = [defaults wmf_inTheNewsMostRecentDateNotificationCount] + 1;
        [defaults wmf_setInTheNewsMostRecentDateNotificationCount:count];
    } else {
        [defaults wmf_setMostRecentInTheNewsNotificationDate:notificationDate];
        [defaults wmf_setInTheNewsMostRecentDateNotificationCount:0];
    }

    return YES;
}

#pragma mark - Utility

- (NSDate *)startDateForPageViewsForDate:(NSDate *)date {
    NSDate *startDate = [[NSCalendar wmf_utcGregorianCalendar] dateByAddingUnit:NSCalendarUnitDay value:-1 - WMFFeedInTheNewsNotificationViewCountDays toDate:date options:NSCalendarMatchStrictly];
    return startDate;
}

- (NSDate *)endDateForPreviewsForDate:(NSDate *)date {
    NSDate *endDate = [[NSCalendar wmf_utcGregorianCalendar] dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:date options:NSCalendarMatchStrictly];
    return endDate;
}

@end

NS_ASSUME_NONNULL_END
