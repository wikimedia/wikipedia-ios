#import "WMFContinueReadingContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "MWKDataStore.h"
#import "WMFArticleDataStore.h"
#import "MWKHistoryEntry.h"
#import "MWKArticle.h"
#import <WMFModel/WMFModel-Swift.h>

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const WMFTimeBeforeDisplayingLastReadArticle = 60 * 60 * 24; //24 hours

@interface WMFContinueReadingContentSource ()

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;
@property (readwrite, nonatomic, strong) WMFArticleDataStore *previewStore;

@end

@implementation WMFContinueReadingContentSource

- (instancetype)initWithContentGroupDataStore:(WMFContentGroupDataStore *)contentStore userDataStore:(MWKDataStore *)userDataStore articlePreviewDataStore:(WMFArticleDataStore *)previewStore {

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

    WMFContentGroup *group = (id)[self.contentStore contentGroupForURL:[WMFContentGroup continueReadingContentGroupURL]];

    if (!shouldShowContinueReading) {
        if (group) {
            [self.contentStore removeContentGroup:group];
        }
        if (completion) {
            completion();
        }
        return;
    }

    NSURL *savedURL = (NSURL *)[group.content firstObject];

    if ([savedURL isEqual:lastRead]) {
        if (completion) {
            completion();
        }
        return;
    }

    WMFArticle *userData = [self.userDataStore fetchArticleForURL:lastRead];

    if (userData == nil) {
        if (completion) {
            completion();
        }
        return;
    }

    group = [self.contentStore createGroupOfKind:WMFContentGroupKindContinueReading forDate:userData.viewedDate withSiteURL:nil associatedContent:@[lastRead]];

    WMF_TECH_DEBT_TODO(Remove this in a later version.A preview will always be available available)
    if (![self.previewStore itemForURL:lastRead]) {
        MWKArticle *article = [self.userDataStore articleWithURL:lastRead];
        NSParameterAssert(article);
        [self.previewStore addPreviewWithURL:lastRead updatedWithArticle:article];
    }
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindContinueReading];
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
