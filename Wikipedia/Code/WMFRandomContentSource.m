#import "WMFRandomContentSource.h"
#import "WMFRandomArticleFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (nonatomic, strong) WMFRandomArticleFetcher *fetcher;

@end

@implementation WMFRandomContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
    }
    return self;
}

- (WMFRandomArticleFetcher *)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[WMFRandomArticleFetcher alloc] init];
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
        NSURL *contentGroupURL = [WMFContentGroup randomContentGroupURLForSiteURL:siteURL midnightUTCDate:date.wmf_midnightUTCDateFromLocalDate];
        WMFContentGroup *existingGroup = [moc contentGroupForURL:contentGroupURL];
        if (existingGroup) {
            if (completion) {
                completion();
            }
            return;
        }
        
        @weakify(self)
        [self.fetcher fetchRandomArticleWithSiteURL:self.siteURL
                                            failure:^(NSError *error) {
                                                if (completion) {
                                                    completion();
                                                }
                                            }
                                            success:^(MWKSearchResult *result) {
                                                @strongify(self);
                                                if (!self) {
                                                    if (completion) {
                                                        completion();
                                                    }
                                                    return;
                                                }
                                                
                                                NSURL *articleURL = [siteURL wmf_URLWithTitle:result.displayTitle];
                                                if (!articleURL) {
                                                    if (completion) {
                                                        completion();
                                                    }
                                                    return;
                                                }
                                                [moc performBlock:^{
                                                    [moc fetchOrCreateGroupForURL:contentGroupURL ofKind:WMFContentGroupKindRandom forDate:date withSiteURL:siteURL associatedContent:@[articleURL] customizationBlock:NULL];
                                                    [moc fetchOrCreateArticleWithURL:articleURL updatedWithSearchResult:result];
                                                    if (completion) {
                                                        completion();
                                                    }
                                                }];

                                            }];
    }];
    
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindRandom];
    
}

@end

NS_ASSUME_NONNULL_END
