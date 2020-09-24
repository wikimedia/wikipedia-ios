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

- (instancetype)initWithSiteURL:(NSURL *)siteURL session:(WMFSession *)session configuration:(WMFConfiguration *)configuration {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.fetcher = [[WMFOnThisDayEventsFetcher alloc] initWithSession:session configuration:configuration];
    }
    return self;
}

#pragma mark - WMFContentSource

- (void)startUpdating {
}

- (void)stopUpdating {
}

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[NSDate date] inManagedObjectContext:moc force:force completion:completion];
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

        NSDateComponents *components = [[NSCalendar wmf_gregorianCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
        NSInteger month = [components month];
        NSInteger day = [components day];
        NSInteger year = [components year];
        @weakify(self)
            [self.fetcher fetchOnThisDayEventsForURL:self.siteURL
                month:month
                day:day
                failure:^(NSError *error) {
                    if (completion) {
                        completion();
                    }
                }
                success:^(NSArray<WMFFeedOnThisDayEvent *> *onThisDayEvents) {
                    @strongify(self);
                    if (onThisDayEvents.count < 1 || !self) {
                        if (completion) {
                            completion();
                        }
                        return;
                    }

                    [moc performBlock:^{
                        [onThisDayEvents enumerateObjectsUsingBlock:^(WMFFeedOnThisDayEvent *_Nonnull event, NSUInteger idx, BOOL *_Nonnull stop) {
                            [event.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull articlePreview, NSUInteger idx, BOOL *_Nonnull stop) {
                                [moc fetchOrCreateArticleWithURL:[articlePreview articleURL] updatedWithFeedPreview:articlePreview pageViews:nil];
                            }];
                            event.score = [event calculateScore];
                            event.index = @(idx);
                        }];

                        NSInteger featuredEventIndex = NSNotFound;

                        NSArray *eventsSortedByScore = [onThisDayEvents sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]]];
                        if (eventsSortedByScore.count > 0) {
                            // Rotate through the 10 highest scoring events based on current year. Ensures unlikely to see a repeat for at least 10 years
                            // (unless the day has fewer than 10 events or a new event re-ranks the top 10) and everyone will see the same featured event
                            // for a given day on a given year.
                            NSInteger index = ((year % 10) % eventsSortedByScore.count);
                            WMFFeedOnThisDayEvent *featuredEvent = eventsSortedByScore[index];
                            featuredEventIndex = featuredEvent.index.integerValue;
                        }

                        WMFContentGroup *group = [self onThisDayForDate:date inManagedObjectContext:moc];
                        if (group == nil) {
                            group = [moc createGroupOfKind:WMFContentGroupKindOnThisDay forDate:date withSiteURL:self.siteURL associatedContent:nil];
                            group.featuredContentIndex = featuredEventIndex;
                            [group setFullContentObject:onThisDayEvents];
                            [group updateContentPreviewWithContent:onThisDayEvents];
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
