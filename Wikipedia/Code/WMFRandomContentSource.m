#import "WMFRandomContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "WMFRandomArticleFetcher.h"
#import "WMFContentGroup.h"

@import NSDate_Extensions;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@property (nonatomic, strong) WMFRandomArticleFetcher *fetcher;

@end

@implementation WMFRandomContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore {
    NSParameterAssert(siteURL);
    NSParameterAssert(contentStore);
    NSParameterAssert(previewStore);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.contentStore = contentStore;
        self.previewStore = previewStore;
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
    [self loadNewContentForce:NO completion:NULL];
}

- (void)stopUpdating {
}

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[NSDate date] force:force completion:completion];
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

    WMFRandomContentGroup *random = [self randomForDate:date];

    if (random != nil) {
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
                    return;
                }

                NSURL *url = [self.siteURL wmf_URLWithTitle:result.displayTitle];

                WMFRandomContentGroup *random = [[WMFRandomContentGroup alloc] initWithDate:date siteURL:self.siteURL];

                [self.previewStore addPreviewWithURL:url updatedWithSearchResult:result];
                [self.contentStore addContentGroup:random associatedContent:@[url]];

                [self.contentStore notifyWhenWriteTransactionsComplete:completion];
            }];
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:[WMFRandomContentGroup kind]];
}

- (nullable WMFRandomContentGroup *)randomForDate:(NSDate *)date {
    return (id)[self.contentStore firstGroupOfKind:[WMFRandomContentGroup kind] forDate:date];
}

@end

NS_ASSUME_NONNULL_END
