#import <WMF/WMFRandomContentSource.h>
#import <WMF/WMFRandomArticleFetcher.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/WMFContentGroup+Extensions.h>
#import <WMF/WMFTaskGroup.h>
#import <WMF/EXTScope.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMFArticle+Extensions.h>

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

                    NSURL *articleURL = [result articleURLForSiteURL:siteURL];
                    if (!articleURL) {
                        if (completion) {
                            completion();
                        }
                        return;
                    }
                    [moc performBlock:^{
                        [moc fetchOrCreateGroupForURL:contentGroupURL
                                               ofKind:WMFContentGroupKindRandom
                                              forDate:date
                                          withSiteURL:siteURL
                                    associatedContent:nil
                                   customizationBlock:^(WMFContentGroup *_Nonnull group) {
                                       group.contentPreview = articleURL;
                                   }];
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
