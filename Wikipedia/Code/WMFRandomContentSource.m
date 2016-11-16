#import "WMFRandomContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "WMFArticleDataStore.h"
#import "WMFRandomArticleFetcher.h"
#import "WMFContentGroup.h"

@import NSDate_Extensions;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRandomContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFArticleDataStore *previewStore;

@property (nonatomic, strong) WMFRandomArticleFetcher *fetcher;

@end

@implementation WMFRandomContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticleDataStore *)previewStore {
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
    NSDate *dateToLoad = [[NSDate date] dateByAddingDays:-days];
    [self loadContentForDate:dateToLoad
                       force:force
                  completion:^{
                      NSInteger numberOfDays = days - 1;
                      if (numberOfDays > 0) {
                          [self preloadContentForNumberOfDays:numberOfDays force:force completion:completion];
                      } else {
                          if (completion) {
                              completion();
                          }
                      }
                  }];
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
