#import "WMFFeedContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "WMFArticleDataStore.h"
#import "WMFFeedContentFetcher.h"

#import "WMFFeedDayResponse.h"
#import "WMFFeedArticlePreview.h"
#import "WMFFeedImage.h"
#import "WMFFeedTopReadResponse.h"
#import "WMFFeedNewsStory.h"

#import "WMFNotificationsController.h"

#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

static NSInteger WMFFeedNotificationMinHour = 8;
static NSInteger WMFFeedNotificationMaxHour = 20;
static NSInteger WMFFeedNotificationMaxPerDay = 3;

static NSTimeInterval WMFFeedNotificationArticleRepeatLimit = 30 * 24 * 60 * 60; // 30 days
static NSInteger WMFFeedInTheNewsNotificationMaxRank = 40;
static NSInteger WMFFeedInTheNewsNotificationViewCountDays = 5;

@interface WMFFeedContentSource () <WMFAnalyticsContextProviding>

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFArticleDataStore *previewStore;
@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;
@property (readwrite, nonatomic, strong) WMFNotificationsController *notificationsController;

@property (readwrite, nonatomic, strong) WMFFeedContentFetcher *fetcher;

@property (readwrite, getter=isSchedulingNotifications) BOOL schedulingNotifications;

@end

@implementation WMFFeedContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticleDataStore *)previewStore userDataStore:(MWKDataStore *)userDataStore notificationsController:(nullable WMFNotificationsController *)notificationsController {
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

- (void)fetchContentForDate:(NSDate *)date force:(BOOL)force completion:(void (^)(WMFFeedDayResponse *__nullable feedResponse, NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *__nullable pageViews))completion {

    [self.fetcher fetchFeedContentForURL:self.siteURL
        date:date
        force:force
        failure:^(NSError *_Nonnull error) {
            if (completion) {
                completion(nil, nil);
            }
        }
        success:^(WMFFeedDayResponse *_Nonnull feedDay) {

            NSMutableDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *pageViews = [NSMutableDictionary dictionary];

            NSDate *startDate = [self startDateForPageViewsForDate:date];
            NSDate *endDate = [self endDateForPageViewsForDate:date];

            WMFTaskGroup *group = [WMFTaskGroup new];

            NSMutableSet *topReadArticleURLKeys = [NSMutableSet setWithCapacity:feedDay.topRead.articlePreviews.count];
            [feedDay.topRead.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedTopReadArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                NSURL *articleURL = obj.articleURL;
                if (!articleURL) {
                    return;
                }
                NSString *databaseKey = articleURL.wmf_articleDatabaseKey;
                if (!databaseKey) {
                    return;
                }
                [topReadArticleURLKeys addObject:databaseKey];
                [group enter];
                [self.fetcher fetchPageviewsForURL:articleURL
                    startDate:startDate
                    endDate:endDate
                    failure:^(NSError *_Nonnull error) {
                        [group leave];

                    }
                    success:^(NSDictionary<NSDate *, NSNumber *> *_Nonnull results) {
                        NSDate *topReadDate = feedDay.topRead.date;
                        NSNumber *topReadViewCount = obj.numberOfViews;
                        if (topReadDate && topReadViewCount && !results[topReadDate]) {
                            NSMutableDictionary *mutableResults = [results mutableCopy];
                            mutableResults[topReadDate] = topReadViewCount;
                            results = mutableResults;
                        }
                        pageViews[articleURL] = results;
                        [group leave];

                    }];
            }];

            [feedDay.newsStories enumerateObjectsUsingBlock:^(WMFFeedNewsStory *_Nonnull newsStory, NSUInteger idx, BOOL *_Nonnull stop) {
                [newsStory.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    NSURL *articleURL = obj.articleURL;
                    if (!articleURL) {
                        return;
                    }
                    NSString *databaseKey = articleURL.wmf_articleDatabaseKey;
                    if (!databaseKey) {
                        return;
                    }
                    if ([topReadArticleURLKeys containsObject:databaseKey]) {
                        return;
                    }
                    [group enter];
                    [self.fetcher fetchPageviewsForURL:articleURL
                        startDate:startDate
                        endDate:endDate
                        failure:^(NSError *_Nonnull error) {
                            [group leave];
                        }
                        success:^(NSDictionary<NSDate *, NSNumber *> *_Nonnull results) {
                            pageViews[articleURL] = results;
                            [group leave];
                        }];
                }];
            }];

            [group waitInBackgroundWithCompletion:^{

                completion(feedDay, pageViews);

            }];
        }];
}

- (void)loadContentForDate:(NSDate *)date force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self fetchContentForDate:date
                        force:force
                   completion:^(WMFFeedDayResponse *_Nullable feedResponse, NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *_Nullable pageViews) {
                       if (feedResponse == nil) {
                           completion();
                       } else {
                           [self saveContentForFeedDay:feedResponse pageViews:pageViews onDate:date completion:completion];
                       }
                   }];
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindFeaturedArticle];
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindPictureOfTheDay];
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindTopRead];
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindNews];
}

#pragma mark - Save Groups

- (void)saveContentForFeedDay:(WMFFeedDayResponse *)feedDay pageViews:(NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews onDate:(NSDate *)date completion:(dispatch_block_t)completion {
    [self saveGroupForFeaturedPreview:feedDay.featuredArticle date:date];
    [self saveGroupForTopRead:feedDay.topRead pageViews:pageViews date:date];
    [self saveGroupForPictureOfTheDay:feedDay.pictureOfTheDay date:date];
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
    if ([calendar isDateInToday:date]) {
        [self saveGroupForNews:feedDay.newsStories pageViews:pageViews date:date];
    }
    [self scheduleNotificationsForFeedDay:feedDay onDate:date];

    if (!completion) {
        return;
    }
    completion();
}

- (void)saveGroupForFeaturedPreview:(WMFFeedArticlePreview *)preview date:(NSDate *)date {
    if (!preview || !date) {
        return;
    }

    WMFContentGroup *featured = [self featuredForDate:date];
    NSURL *featuredURL = [preview articleURL];

    if (!featuredURL) {
        return;
    }

    [self.previewStore addPreviewWithURL:featuredURL updatedWithFeedPreview:preview pageViews:nil];

    if (featured == nil) {
        [self.contentStore createGroupOfKind:WMFContentGroupKindFeaturedArticle forDate:date withSiteURL:self.siteURL associatedContent:@[featuredURL]];
    } else if (featured.content == nil) {
        featured.content = @[featuredURL];
    }
}

- (void)saveGroupForTopRead:(WMFFeedTopReadResponse *)topRead pageViews:(NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews date:(NSDate *)date {
    //Sometimes top read is nil, depends on time of day
    if ([topRead.articlePreviews count] == 0 || date == nil) {
        return;
    }

    [topRead.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedTopReadArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSURL *url = [obj articleURL];
        [self.previewStore addPreviewWithURL:url updatedWithFeedPreview:obj pageViews:pageViews[url]];
    }];

    WMFContentGroup *group = [self topReadForDate:date];

    if (group == nil) {
        [self.contentStore createGroupOfKind:WMFContentGroupKindTopRead
                                     forDate:date
                                 withSiteURL:self.siteURL
                           associatedContent:topRead.articlePreviews
                          customizationBlock:^(WMFContentGroup *_Nonnull group) {
                              group.contentMidnightUTCDate = topRead.date.wmf_midnightUTCDateFromLocalDate;
                          }];
    } else if (group.content == nil) {
        group.content = topRead.articlePreviews;
    }
}

- (void)saveGroupForPictureOfTheDay:(WMFFeedImage *)image date:(NSDate *)date {
    if (image == nil || date == nil) {
        return;
    }

    WMFContentGroup *group = [self pictureOfTheDayForDate:date];

    if (group == nil) {
        [self.contentStore createGroupOfKind:WMFContentGroupKindPictureOfTheDay forDate:date withSiteURL:self.siteURL associatedContent:@[image]];
    } else if (group.content == nil) {
        group.content = @[image];
    }
}

- (void)saveGroupForNews:(NSArray<WMFFeedNewsStory *> *)news pageViews:(NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews date:(NSDate *)date {
    if ([news count] == 0 || date == nil) {
        return;
    }

    WMFContentGroup *group = [self newsForDate:date];

    if (group == nil) {
        [self.contentStore createGroupOfKind:WMFContentGroupKindNews forDate:date withSiteURL:self.siteURL associatedContent:news];
    } else if (group.content == nil) {
        group.content = news;
    }

    [news enumerateObjectsUsingBlock:^(WMFFeedNewsStory *_Nonnull story, NSUInteger idx, BOOL *_Nonnull stop) {
        [story.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            NSURL *url = [obj articleURL];
            NSDictionary<NSDate *, NSNumber *> *pageViewsForURL = pageViews[url];
            [self.previewStore addPreviewWithURL:url updatedWithFeedPreview:obj pageViews:pageViewsForURL];
        }];
        story.featuredArticlePreview = story.articlePreviews.firstObject;
    }];
}

#pragma mark - Find Groups

- (nullable WMFContentGroup *)featuredForDate:(NSDate *)date {
    return (id)[self.contentStore firstGroupOfKind:WMFContentGroupKindFeaturedArticle forDate:date siteURL:self.siteURL];
}

- (nullable WMFContentGroup *)pictureOfTheDayForDate:(NSDate *)date {
    //NOTE: POTDs are the same across languages so we do not not want to constrain our search by site URL as this will cause duplicates
    return (id)[self.contentStore firstGroupOfKind:WMFContentGroupKindPictureOfTheDay forDate:date];
}

- (nullable WMFContentGroup *)topReadForDate:(NSDate *)date {
    return (id)[self.contentStore firstGroupOfKind:WMFContentGroupKindTopRead forDate:date siteURL:self.siteURL];
}

- (nullable WMFContentGroup *)newsForDate:(NSDate *)date {
    return (id)[self.contentStore firstGroupOfKind:WMFContentGroupKindNews forDate:date siteURL:self.siteURL];
}

#pragma mark - Notifications

- (void)scheduleNotificationsForFeedDay:(WMFFeedDayResponse *)feedDay onDate:(NSDate *)date {
    if (!self.isNotificationSchedulingEnabled) {
        return;
    }

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

    self.schedulingNotifications = YES;
    dispatch_block_t done = ^{
        self.schedulingNotifications = NO;
    };

    NSArray<WMFFeedTopReadArticlePreview *> *articlePreviews = feedDay.topRead.articlePreviews;
    NSMutableDictionary<NSString *, WMFFeedTopReadArticlePreview *> *topReadArticlesByKey = [NSMutableDictionary dictionaryWithCapacity:articlePreviews.count];
    for (WMFFeedTopReadArticlePreview *articlePreview in articlePreviews) {
        NSString *key = articlePreview.articleURL.wmf_articleDatabaseKey;
        if (!key) {
            continue;
        }
        topReadArticlesByKey[key] = articlePreview;
    }

    WMFFeedNewsStory *newsStory = feedDay.newsStories.firstObject;

    if (!newsStory) {
        done();
        return;
    }

    WMFArticle *articlePreviewToNotifyAbout = nil;
    WMFFeedArticlePreview *articlePreview = newsStory.featuredArticlePreview;
    if (!articlePreview) {
        done();
        return;
    }

    NSURL *articleURL = articlePreview.articleURL;
    if (!articleURL) {
        done();
        return;
    }

    NSString *key = articleURL.wmf_articleDatabaseKey;
    if (!key) {
        done();
        return;
    }

    WMFArticle *entry = [self.userDataStore fetchArticleForURL:articlePreview.articleURL];
    if (entry) {
        BOOL notifiedRecently = entry.newsNotificationDate && [entry.newsNotificationDate timeIntervalSinceNow] < WMFFeedNotificationArticleRepeatLimit;
        if (notifiedRecently || entry.isExcludedFromFeed) {
            articlePreviewToNotifyAbout = nil;
            done();
            return;
        }
    }

    WMFFeedTopReadArticlePreview *topReadArticlePreview = topReadArticlesByKey[key];
    if (topReadArticlePreview && (topReadArticlePreview.rank.integerValue < WMFFeedInTheNewsNotificationMaxRank)) {
        articlePreviewToNotifyAbout = [self.previewStore itemForURL:articleURL];
    }

    if (!articlePreviewToNotifyAbout.URL) {
        done();
        return;
    }

    if (![self scheduleNotificationForNewsStory:newsStory articlePreview:articlePreviewToNotifyAbout force:NO]) {
        done();
        return;
    }

    [[PiwikTracker sharedInstance] wmf_logActionPushInContext:self contentType:articlePreviewToNotifyAbout.URL.host date:[NSDate date]];

    done();
}

- (BOOL)scheduleNotificationForNewsStory:(WMFFeedNewsStory *)newsStory
                          articlePreview:(WMFArticle *)articlePreview
                                   force:(BOOL)force {
    if (!newsStory.featuredArticlePreview) {
        NSString *articlePreviewKey = articlePreview.URL.wmf_articleDatabaseKey;
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

    NSString *articleURLString = articlePreview.URL.absoluteString;
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

    NSString *title = MWLocalizedString(@"in-the-news-title", nil);
    NSString *body = [storyHTML wmf_stringByRemovingHTML];

    NSDate *notificationDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
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
        NSCalendar *userCalendar = [NSCalendar wmf_gregorianCalendar];
        NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
        NSDate *mostRecentDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
        if (notificationDate && mostRecentDate && [userCalendar wmf_daysFromDate:notificationDate toDate:mostRecentDate] > 0) { // don't send if we have a notification scheduled for tomorrow already
            return NO;
        }
        if (mostRecentDate && notificationDate && [userCalendar isDate:mostRecentDate inSameDayAsDate:notificationDate]) {
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

@end

NS_ASSUME_NONNULL_END
