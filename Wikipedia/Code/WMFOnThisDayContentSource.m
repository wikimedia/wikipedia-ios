#import <WMF/WMFOnThisDayContentSource.h>
#import <WMF/WMFOnThisDayEventsFetcher.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/WMFContentGroup+Extensions.h>
#import <WMF/WMFTaskGroup.h>
#import <WMF/EXTScope.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMFArticle+Extensions.h>
#import <WMF/WMFFeedOnThisDayEvent.h>
#import <WMF/WMFFeedArticlePreview.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFOnThisDayContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (nonatomic, strong) WMFOnThisDayEventsFetcher *fetcher;

@end

@implementation WMFOnThisDayContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
    }
    return self;
}

- (WMFOnThisDayEventsFetcher *)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[WMFOnThisDayEventsFetcher alloc] init];
    }
    return _fetcher;
}

#pragma mark - WMFContentSource

- (void)startUpdating {
}

- (void)stopUpdating {
}

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[NSDate date] inManagedObjectContext:moc force:force completion:completion];
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
            inManagedObjectContext:moc
                             force:force
                        completion:^{
                            [group leave];
                        }];
    }

    [group waitInBackgroundWithCompletion:completion];
}

- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    NSURL *siteURL = self.siteURL;

    if (!siteURL) {
        if (completion) {
            completion();
        }
        return;
    }
    [moc performBlock:^{
        NSURL *contentGroupURL = [WMFContentGroup onThisDayContentGroupURLForSiteURL:siteURL midnightUTCDate:date.wmf_midnightUTCDateFromLocalDate];
        WMFContentGroup *existingGroup = [moc contentGroupForURL:contentGroupURL];
        if (existingGroup) {
            if (completion) {
                completion();
            }
            return;
        }

        NSDateComponents *components = [[NSCalendar wmf_gregorianCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth fromDate:date];
        NSInteger monthNumber = [components month];
        NSInteger dayNumber = [components day];
        @weakify(self)
            [self.fetcher fetchOnThisDayEventsForURL:self.siteURL
                month:monthNumber
                day:dayNumber
                failure:^(NSError *error) {
                    if (completion) {
                        completion();
                    }
                }
                success:^(NSArray<WMFFeedOnThisDayEvent *> *onThisDayEvents) {
                    @strongify(self);
                    if (!self) {
                        if (completion) {
                            completion();
                        }
                        return;
                    }

                    [moc performBlock:^{
                        [onThisDayEvents enumerateObjectsUsingBlock:^(WMFFeedOnThisDayEvent *_Nonnull event, NSUInteger idx, BOOL *_Nonnull stop) {
                            [event.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                [moc fetchOrCreateArticleWithURL:[obj articleURL] updatedWithFeedPreview:obj pageViews:nil];
                            }];
                        }];

                        WMFContentGroup *group = [self onThisDayForDate:date inManagedObjectContext:moc];
                        if (group == nil) {
                            [moc createGroupOfKind:WMFContentGroupKindOnThisDay forDate:date withSiteURL:self.siteURL associatedContent:onThisDayEvents];
                        } else {
                            group.content = onThisDayEvents;
                        }

                        if (completion) {
                            completion();
                        }
                    }];

                }];
    }];
}

- (nullable WMFContentGroup *)onThisDayForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc {
    return (id)[moc groupOfKind:WMFContentGroupKindOnThisDay forDate:date siteURL:self.siteURL];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindOnThisDay];
}

@end

NS_ASSUME_NONNULL_END
