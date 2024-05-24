#import <WMF/WMFFeedContentSource.h>
#import <WMF/WMFFeedContentFetcher.h>

#import <WMF/WMFFeedDayResponse.h>
#import <WMF/WMFFeedArticlePreview.h>
#import <WMF/WMFFeedImage.h>
#import <WMF/WMFFeedTopReadResponse.h>
#import <WMF/WMFFeedNewsStory.h>

#import <WMF/WMFNotificationsController.h>

#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

NSInteger const WMFFeedInTheNewsNotificationViewCountDays = 5;

@interface WMFFeedContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (readwrite, nonatomic, weak) MWKDataStore *userDataStore;
@property (readwrite, nonatomic, strong) WMFNotificationsController *notificationsController;

@property (readwrite, nonatomic, strong) WMFFeedContentFetcher *fetcher;

@end

@implementation WMFFeedContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL userDataStore:(MWKDataStore *)userDataStore {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.userDataStore = userDataStore;
        self.notificationsController = userDataStore.notificationsController;
    }
    return self;
}

#pragma mark - Accessors

- (WMFFeedContentFetcher *)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[WMFFeedContentFetcher alloc] initWithSession:self.userDataStore.session configuration:self.userDataStore.configuration];
    }
    return _fetcher;
}

#pragma mark - WMFContentSource

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    NSDate *date = [NSDate date];
    [self loadContentForDate:date inManagedObjectContext:moc force:force completion:completion];
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
                NSString *databaseKey = articleURL.wmf_databaseKey;
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
                    NSString *databaseKey = articleURL.wmf_databaseKey;
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
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindOnThisDay];
}

#pragma mark - Save Groups

- (void)saveContentForFeedDay:(WMFFeedDayResponse *)feedDay pageViews:(NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews onDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc completion:(dispatch_block_t)completion {
    [moc performBlock:^{
        NSString *key = [WMFFeedDayResponse WMFFeedDayResponseMaxAgeKey];
        NSNumber *value = @(feedDay.maxAge);
        [moc wmf_setValue:value forKey:key];

        [self saveGroupForFeaturedPreview:feedDay.featuredArticle date:date inManagedObjectContext:moc];
        [self saveGroupForTopRead:feedDay.topRead pageViews:pageViews date:date inManagedObjectContext:moc];
        [self saveGroupForPictureOfTheDay:feedDay.pictureOfTheDay date:date inManagedObjectContext:moc];
        [self saveGroupForNews:feedDay.newsStories pageViews:pageViews date:date inManagedObjectContext:moc];

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

    [moc fetchOrCreateArticleWithURL:featuredURL updatedWithFeedPreview:preview pageViews:nil isFeatured:YES];

    if (featured == nil) {
        [moc createGroupOfKind:WMFContentGroupKindFeaturedArticle forDate:date withSiteURL:self.siteURL associatedContent:@[featuredURL]];
    } else if (featured.contentPreview == nil) {
        featured.contentPreview = featuredURL;
    }
}

- (void)saveGroupForTopRead:(WMFFeedTopReadResponse *)topRead pageViews:(NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews date:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    // Sometimes top read is nil, depends on time of day
    if ([topRead.articlePreviews count] == 0 || date == nil) {
        return;
    }

    [topRead.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedTopReadArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSURL *url = [obj articleURL];
        [moc fetchOrCreateArticleWithURL:url updatedWithFeedPreview:obj pageViews:pageViews[url] isFeatured:NO];
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
    } else {
        group.fullContentObject = topRead.articlePreviews;
        [group updateContentPreviewWithContent:topRead.articlePreviews];
    }
}

- (void)saveGroupForPictureOfTheDay:(WMFFeedImage *)image date:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    if (image == nil || date == nil) {
        return;
    }
    
    NSString *primaryLanguage = self.userDataStore.languageLinkController.appLanguage.contentLanguageCode;
    NSString *feedLanguage = [self.siteURL wmf_contentLanguageCode];
    BOOL isPrimaryLanguageFeed = [feedLanguage wmf_isEqualToStringIgnoringCase:primaryLanguage];
    
    // T356255 - the POTD is the same across all feeds (i.e. same image, different localized description).
    // To prevent the same image from showing on each language feed, we save the POTD for the primary language only
    // (and clean up any secondary / duplicate ones - secondary ones may exist when the user has removed a language
    // or changed the app primary language).
    
    if (isPrimaryLanguageFeed) {
        [self insertOrUpdatePictureOfTheDayForImage:image date:date inManagedObjectContext:moc];
        [self removeDuplicatePicturesOfTheDayForDate:date inManagedObjectContext:moc];
    }
}

- (void)insertOrUpdatePictureOfTheDayForImage:(WMFFeedImage *)image date:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    WMFContentGroup * group = [self pictureOfTheDayForDate:date inManagedObjectContext:moc];
    
    if (group == nil) {
        DDLogDebug(@"Creating POTD content group for language code: [%@]", [self.siteURL wmf_contentLanguageCode]);
        group = [moc createGroupOfKind:WMFContentGroupKindPictureOfTheDay forDate:date withSiteURL:self.siteURL associatedContent:nil];
    } else {
        DDLogDebug(@"Updating POTD content group for language code: [%@]", [self.siteURL wmf_contentLanguageCode]);
    }
    
    group.contentPreview = image;
}

- (void)removeDuplicatePicturesOfTheDayForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    
    NSArray<WMFContentGroup *> *allPicturesOfTheDay = [self allPicturesOfTheDayForDate:date inManagedObjectContext:moc];
    NSString *primaryLanguageCode = self.userDataStore.languageLinkController.appLanguage.contentLanguageCode;

    for (WMFContentGroup *contentGroup in allPicturesOfTheDay) {
        NSString *contentGroupLanguageCode = [contentGroup.siteURL wmf_contentLanguageCode];
        if (![primaryLanguageCode wmf_isEqualToStringIgnoringCase:contentGroupLanguageCode]) {
            DDLogDebug(@"Deleting POTD content group for secondary language code: [%@]", contentGroupLanguageCode);
            [moc removeContentGroup:contentGroup];
        }
    }
}

- (void)saveGroupForNews:(NSArray<WMFFeedNewsStory *> *)news pageViews:(NSDictionary<NSURL *, NSDictionary<NSDate *, NSNumber *> *> *)pageViews date:(NSDate *)feedDate inManagedObjectContext:(NSManagedObjectContext *)moc {

    // Search for a previously added news group with this date.
    // Invisible news groups are created when an older news story is loaded.
    // If the user has now scrolled to this older date, show the older news story.
    WMFContentGroup *newsGroupForFeedDate = [self newsForDate:feedDate inManagedObjectContext:moc];
    if (newsGroupForFeedDate) {
        newsGroupForFeedDate.isVisible = YES;
    }

    if ([news count] == 0 || feedDate == nil) {
        return;
    }

    WMFFeedNewsStory *firstStory = [news firstObject];
    NSDate *midnightMonthAndDay = firstStory.midnightUTCMonthAndDay;
    NSDate *storyDate = feedDate;
    NSCalendar *utcCalendar = NSCalendar.wmf_utcGregorianCalendar;
    if (midnightMonthAndDay && storyDate) {
        // This logic assumes we won't be loading something more than 30 days old
        NSDateComponents *storyComponents = [utcCalendar components:NSCalendarUnitMonth | NSCalendarUnitDay fromDate:midnightMonthAndDay];
        NSCalendar *localCalendar = NSCalendar.wmf_gregorianCalendar;
        NSDateComponents *components = [localCalendar components:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear fromDate:storyDate];
        if (storyComponents.month > components.month + 1) { // probably not how this should be done
            components.year = components.year - 1;          // assume it's last year
        } else if (components.month > storyComponents.month + 1) {
            components.year = components.year + 1; // assume it's next year
        }
        components.day = storyComponents.day;
        components.month = storyComponents.month;
        storyDate = [localCalendar dateFromComponents:components];
    }

    if (!storyDate) {
        return;
    }

    // Check that the news story date matches the feed date being requested
    // If the dates don't match, add the section but make it invisible.
    BOOL isVisible = YES;
    NSDate *feedMidnightUTCDate = [feedDate wmf_midnightUTCDateFromLocalDate];
    NSDate *storyMidnightUTCDate = [storyDate wmf_midnightUTCDateFromLocalDate];
    if (feedMidnightUTCDate && storyMidnightUTCDate && [utcCalendar wmf_daysFromDate:storyMidnightUTCDate toDate:feedMidnightUTCDate] > 1) {
        WMFContentGroup *featuredGroup = [self featuredForDate:storyDate inManagedObjectContext:moc];
        isVisible = featuredGroup != nil; // hide the news story if we haven't loaded that day yet
    }

    [news enumerateObjectsUsingBlock:^(WMFFeedNewsStory *_Nonnull story, NSUInteger idx, BOOL *_Nonnull stop) {
        [story.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            NSURL *url = [obj articleURL];
            NSDictionary<NSDate *, NSNumber *> *pageViewsForURL = pageViews[url];
            [moc fetchOrCreateArticleWithURL:url updatedWithFeedPreview:obj pageViews:pageViewsForURL isFeatured:NO];
        }];

        NSString *featuredArticleTitleBasedOnSemanticLookup = [WMFFeedNewsStory semanticFeaturedArticleTitleFromStoryHTML:story.storyHTML siteURL:self.siteURL];
        for (WMFFeedArticlePreview *preview in story.articlePreviews) {
            if (preview.thumbnailURL == nil) {
                continue;
            }
            NSString *displayTitle = preview.displayTitle;
            if (displayTitle && featuredArticleTitleBasedOnSemanticLookup && [displayTitle caseInsensitiveCompare:featuredArticleTitleBasedOnSemanticLookup] == NSOrderedSame) {
                story.featuredArticlePreview = preview;
                break;
            } else if (!story.featuredArticlePreview) {
                story.featuredArticlePreview = preview;
            }
        }

        if (story.featuredArticlePreview == nil) {
            story.featuredArticlePreview = story.articlePreviews.firstObject;
        }
    }];

    WMFContentGroup *newsGroup = [self newsForDate:storyDate inManagedObjectContext:moc];
    if (newsGroup == nil) {
        newsGroup = [moc createGroupOfKind:WMFContentGroupKindNews forDate:storyDate withSiteURL:self.siteURL associatedContent:news];
    } else {
        newsGroup.fullContentObject = news;
        [newsGroup updateContentPreviewWithContent:news];
    }
    newsGroup.isVisible = isVisible;
}

#pragma mark - Find Groups

- (nullable WMFContentGroup *)featuredForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindFeaturedArticle forDate:date siteURL:self.siteURL];
}

- (nullable WMFContentGroup *)pictureOfTheDayForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindPictureOfTheDay forDate:date siteURL:self.siteURL];
}

- (nullable NSArray<WMFContentGroup *> *)allPicturesOfTheDayForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupsOfKind:WMFContentGroupKindPictureOfTheDay forDate:date];
}

- (nullable WMFContentGroup *)topReadForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindTopRead forDate:date siteURL:self.siteURL];
}

- (nullable WMFContentGroup *)newsForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindNews forDate:date siteURL:self.siteURL];
}

- (nullable WMFContentGroup *)onThisDayForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindOnThisDay forDate:date siteURL:self.siteURL];
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
