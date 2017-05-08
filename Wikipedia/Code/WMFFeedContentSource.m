#import "WMFFeedContentSource.h"
#import "WMFFeedContentFetcher.h"

#import "WMFFeedDayResponse.h"
#import "WMFFeedArticlePreview.h"
#import "WMFFeedImage.h"
#import "WMFFeedTopReadResponse.h"
#import "WMFFeedNewsStory.h"

#import "WMFNotificationsController.h"

#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

NSInteger const WMFFeedNotificationMinHour = 8;
NSInteger const WMFFeedNotificationMaxHour = 20;
NSInteger const WMFFeedNotificationMaxPerDay = 3;

NSTimeInterval const WMFFeedNotificationArticleRepeatLimit = 30 * 24 * 60 * 60; // 30 days
NSInteger const WMFFeedInTheNewsNotificationMaxRank = 40;
NSInteger const WMFFeedInTheNewsNotificationViewCountDays = 5;

@interface WMFFeedContentSource () <WMFAnalyticsContextProviding>

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;
@property (readwrite, nonatomic, strong) WMFNotificationsController *notificationsController;

@property (readwrite, nonatomic, strong) WMFFeedContentFetcher *fetcher;

@property (readwrite, getter=isSchedulingNotifications) BOOL schedulingNotifications;

@end

@implementation WMFFeedContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL userDataStore:(MWKDataStore *)userDataStore notificationsController:(nullable WMFNotificationsController *)notificationsController {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
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

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    NSDate *date = [NSDate date];
    [self loadContentForDate:date inManagedObjectContext:moc force:force completion:completion];
}

- (void)preloadContentForNumberOfDays:(NSInteger)days inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
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
         inManagedObjectContext:(NSManagedObjectContext *)moc
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

- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self fetchContentForDate:date
                        force:force
                   completion:^(WMFFeedDayResponse *_Nullable feedResponse, NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *_Nullable pageViews) {
                       if (feedResponse == nil) {
                           completion();
                       } else {
                           [self saveContentForFeedDay:feedResponse pageViews:pageViews onDate:date inManagedObjectContext:moc completion:completion];
                       }
                   }];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindFeaturedArticle];
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindPictureOfTheDay];
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindTopRead];
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindNews];
}

#pragma mark - Save Groups

- (void)saveContentForFeedDay:(WMFFeedDayResponse *)feedDay pageViews:(NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews onDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc completion:(dispatch_block_t)completion {
    [moc performBlock:^{
        [self saveGroupForFeaturedPreview:feedDay.featuredArticle date:date inManagedObjectContext:moc];
        [self saveGroupForTopRead:feedDay.topRead pageViews:pageViews date:date inManagedObjectContext:moc];
        [self saveGroupForPictureOfTheDay:feedDay.pictureOfTheDay date:date inManagedObjectContext:moc];
        NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
        if ([calendar isDateInToday:date]) {
            [self saveGroupForNews:feedDay.newsStories pageViews:pageViews date:date inManagedObjectContext:moc];
        }
        [self scheduleNotificationsForFeedDay:feedDay onDate:date inManagedObjectContext:moc];
        
        if (!completion) {
            return;
        }
        completion();
    }];
}

- (void)saveGroupForFeaturedPreview:(WMFFeedArticlePreview *)preview date:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    if (!preview || !date) {
        return;
    }

    WMFContentGroup *featured = [self featuredForDate:date inManagedObjectContext:moc];
    NSURL *featuredURL = [preview articleURL];

    if (!featuredURL) {
        return;
    }

    [moc fetchOrCreateArticleWithURL:featuredURL updatedWithFeedPreview:preview pageViews:nil];

    if (featured == nil) {
        [moc createGroupOfKind:WMFContentGroupKindFeaturedArticle forDate:date withSiteURL:self.siteURL associatedContent:@[featuredURL]];
    } else if (featured.content == nil) {
        featured.content = @[featuredURL];
    }
}

- (void)saveGroupForTopRead:(WMFFeedTopReadResponse *)topRead pageViews:(NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews date:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    //Sometimes top read is nil, depends on time of day
    if ([topRead.articlePreviews count] == 0 || date == nil) {
        return;
    }

    [topRead.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedTopReadArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSURL *url = [obj articleURL];
        [moc fetchOrCreateArticleWithURL:url updatedWithFeedPreview:obj pageViews:pageViews[url]];
    }];

    WMFContentGroup *group = [self topReadForDate:date inManagedObjectContext:moc];

    if (group == nil) {
        [moc createGroupOfKind:WMFContentGroupKindTopRead
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

- (void)saveGroupForPictureOfTheDay:(WMFFeedImage *)image date:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    if (image == nil || date == nil) {
        return;
    }

    WMFContentGroup *group = [self pictureOfTheDayForDate:date inManagedObjectContext:moc];

    if (group == nil) {
        [moc createGroupOfKind:WMFContentGroupKindPictureOfTheDay forDate:date withSiteURL:self.siteURL associatedContent:@[image]];
    } else if (group.content == nil) {
        group.content = @[image];
    }
}

- (void)saveGroupForNews:(NSArray<WMFFeedNewsStory *> *)news pageViews:(NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews date:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    if ([news count] == 0 || date == nil) {
        return;
    }

    WMFContentGroup *group = [self newsForDate:date inManagedObjectContext:moc];

    if (group == nil) {
        [moc createGroupOfKind:WMFContentGroupKindNews forDate:date withSiteURL:self.siteURL associatedContent:news];
    } else if (group.content == nil) {
        group.content = news;
    }

    [news enumerateObjectsUsingBlock:^(WMFFeedNewsStory *_Nonnull story, NSUInteger idx, BOOL *_Nonnull stop) {
        [story.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            NSURL *url = [obj articleURL];
            NSDictionary<NSDate *, NSNumber *> *pageViewsForURL = pageViews[url];
            [moc fetchOrCreateArticleWithURL:url updatedWithFeedPreview:obj pageViews:pageViewsForURL];
        }];

        for (WMFFeedArticlePreview *preview in story.articlePreviews) {
            if (preview.thumbnailURL == nil) {
                continue;
            }
            story.featuredArticlePreview = preview;
            break;
        }

        if (story.featuredArticlePreview == nil) {
            story.featuredArticlePreview = story.articlePreviews.firstObject;
        }
    }];
}

#pragma mark - Find Groups

- (nullable WMFContentGroup *)featuredForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindFeaturedArticle forDate:date siteURL:self.siteURL];
}

- (nullable WMFContentGroup *)pictureOfTheDayForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    //NOTE: POTDs are the same across languages so we do not not want to constrain our search by site URL as this will cause duplicates
    return (id)[moc groupOfKind:WMFContentGroupKindPictureOfTheDay forDate:date];
}

- (nullable WMFContentGroup *)topReadForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindTopRead forDate:date siteURL:self.siteURL];
}

- (nullable WMFContentGroup *)newsForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindNews forDate:date siteURL:self.siteURL];
}

#pragma mark - Notifications

- (void)scheduleNotificationsForFeedDay:(WMFFeedDayResponse *)feedDay onDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
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

    WMFArticle *entry = [moc fetchArticleWithURL:articlePreview.articleURL];
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
        articlePreviewToNotifyAbout = [moc fetchArticleWithURL:articleURL];
    }

    if (!articlePreviewToNotifyAbout.URL) {
        done();
        return;
    }

    if (![self scheduleNotificationForNewsStory:newsStory articlePreview:articlePreviewToNotifyAbout inManagedObjectContext:moc force:NO]) {
        done();
        return;
    }

    [[PiwikTracker sharedInstance] wmf_logActionPushInContext:self contentType:articlePreviewToNotifyAbout.URL.host date:[NSDate date]];

    done();
}

- (BOOL)scheduleNotificationForNewsStory:(WMFFeedNewsStory *)newsStory
                          articlePreview:(WMFArticle *)articlePreview
                  inManagedObjectContext:(NSManagedObjectContext *)moc
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

    NSString *title = WMFLocalizedStringWithDefaultValue(@"in-the-news-title", nil, nil, @"In the news", @"Title for the 'In the news' notification & feed section");
    NSString *body = [storyHTML wmf_stringByRemovingHTML];

    NSDate *notificationDate = [NSDate date];
    NSCalendar *userCalendar = [NSCalendar wmf_gregorianCalendar];
    NSDateComponents *notificationDateComponents = [userCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:notificationDate];

    if (force) {
        // nil the components to indicate it should be sent immediately, date should still be [NSDate date]
        notificationDateComponents = nil;
    } else {
        if (notificationDateComponents.hour < WMFFeedNotificationMinHour) {
            notificationDateComponents.hour = WMFFeedNotificationMinHour;
            notificationDateComponents.minute = 1;
            notificationDate = [userCalendar dateFromComponents:notificationDateComponents];
        } else if (notificationDateComponents.hour > WMFFeedNotificationMaxHour) {
            // Send it tomorrow
            notificationDate = [userCalendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:notificationDate options:NSCalendarMatchStrictly];
            notificationDateComponents = [userCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:notificationDate];
            notificationDateComponents.hour = WMFFeedNotificationMinHour;
            notificationDateComponents.minute = 1;
            notificationDate = [userCalendar dateFromComponents:notificationDateComponents];
        } else {
            // nil the components to indicate it should be sent immediately, date should still be [NSDate date]
            notificationDateComponents = nil;
        }
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
    
    for (NSURL *URL in articleURLs) {
        WMFArticle *article = [moc fetchOrCreateArticleWithURL:URL];
        article.newsNotificationDate = notificationDate;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    NSDate *mostRecentDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
    if (notificationDate && mostRecentDate && [userCalendar isDate:mostRecentDate inSameDayAsDate:notificationDate]) {
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
