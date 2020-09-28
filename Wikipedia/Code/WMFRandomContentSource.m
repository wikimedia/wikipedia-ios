#import <WMF/WMFRandomContentSource.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/WMFContentGroup+Extensions.h>
#import <WMF/WMFTaskGroup.h>
#import <WMF/EXTScope.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMFArticle+Extensions.h>
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (nonatomic, strong) WMFRandomArticleFetcher *fetcher;

@end

@implementation WMFRandomContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL session:(WMFSession *)session configuration:(WMFConfiguration *)configuration {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.fetcher = [[WMFRandomArticleFetcher alloc] initWithSession:session configuration:configuration];
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
        NSURL *contentGroupURL = [WMFContentGroup randomContentGroupURLForSiteURL:siteURL midnightUTCDate:date.wmf_midnightUTCDateFromLocalDate];
        WMFContentGroup *existingGroup = [moc contentGroupForURL:contentGroupURL];
        if (existingGroup) {
            if (completion) {
                completion();
            }
            return;
        }

        @weakify(self)
        [self.fetcher fetchRandomArticleWithSiteURL:self.siteURL completion:^(NSError * _Nullable error, NSURL * _Nullable articleURL, WMFArticleSummary * _Nullable summary) {
            if (error || !articleURL) {
                if (completion) {
                    completion();
                }
            } else {
                @strongify(self);
                if (!self) {
                    if (completion) {
                        completion();
                    }
                    return;
                }

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
                    WMFArticle *article = [moc fetchOrCreateArticleWithURL:articleURL updatedWithSearchResult:nil];
                    [article updateWithSummary:summary];
                    if (completion) {
                        completion();
                    }
                }];
            }
        }];
    }];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindRandom];
}

@end

NS_ASSUME_NONNULL_END
