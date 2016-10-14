#import "WMFContinueReadingContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "MWKDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "MWKHistoryEntry.h"
#import "WMFArticlePreview.h"
#import "WMFContentGroup+WMFDatabaseStorable.h"
#import "MWKArticle.h"
#import <WMFModel/WMFModel-Swift.h>

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const WMFTimeBeforeDisplayingLastReadArticle = 60 * 60 * 24; //24 hours

@interface WMFContinueReadingContentSource ()

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;
@property (readwrite, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@end

@implementation WMFContinueReadingContentSource

- (instancetype)initWithContentGroupDataStore:(WMFContentGroupDataStore *)contentStore userDataStore:(MWKDataStore *)userDataStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore {

    NSParameterAssert(contentStore);
    NSParameterAssert(userDataStore);
    NSParameterAssert(previewStore);
    self = [super init];
    if (self) {
        self.contentStore = contentStore;
        self.userDataStore = userDataStore;
        self.previewStore = previewStore;
    }
    return self;
}

#pragma mark - WMFContentSource

- (void)startUpdating {
    [self observeSavedPages];
    [self loadNewContentForce:NO completion:NULL];
}

- (void)stopUpdating {
    [self unobserveSavedPages];
}

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {

    NSURL *lastRead = [[NSUserDefaults wmf_userDefaults] wmf_openArticleURL];

    if (!lastRead) {
        if (completion) {
            completion();
        }
        return;
    }

    NSDate *resignActiveDate = [[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate];

    BOOL const shouldShowContinueReading =
        NO /*FBTweakValue(@"Explore", @"Continue Reading", @"Always Show", NO)*/ ||
        fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeDisplayingLastReadArticle;

    WMFContinueReadingContentGroup *group = (id)[self.contentStore contentGroupForURL:[WMFContinueReadingContentGroup url]];

    if (!shouldShowContinueReading) {
        if (group) {
            [self.contentStore removeContentGroup:group];
        }
        if (completion) {
            completion();
        }
        return;
    }

    NSURL *savedURL = [[self.contentStore contentForContentGroup:group] firstObject];

    if ([savedURL isEqual:lastRead]) {
        if (completion) {
            completion();
        }
        return;
    }

    MWKHistoryEntry *userData = [self.userDataStore entryForURL:lastRead];

    group = [[WMFContinueReadingContentGroup alloc] initWithDate:userData.dateViewed];

    WMFArticlePreview *preview = [self.previewStore itemForURL:lastRead];

    WMF_TECH_DEBT_TODO(Remove this in a later version.A preview will always be available available)
    if (!preview) {
        MWKArticle *article = [self.userDataStore articleWithURL:lastRead];
        NSParameterAssert(article);
        preview = [self.previewStore addPreviewWithURL:lastRead updatedWithArticle:article];
    }

    //preview should already exist for any item in history
    NSParameterAssert(preview);

    [self.contentStore addContentGroup:group associatedContent:@[lastRead]];
    [self.contentStore notifyWhenWriteTransactionsComplete:completion];
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:[WMFContinueReadingContentGroup kind]];
}

#pragma mark - Observing

- (void)itemWasUpdated:(NSNotification *)note {
    [self loadNewContentForce:NO completion:NULL];
}

- (void)observeSavedPages {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemWasUpdated:) name:MWKItemUpdatedNotification object:nil];
}

- (void)unobserveSavedPages {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

NS_ASSUME_NONNULL_END
