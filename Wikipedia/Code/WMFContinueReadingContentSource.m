#import <WMF/WMFContinueReadingContentSource.h>
#import <WMF/MWKDataStore.h>
#import <WMF/MWKHistoryEntry.h>
#import <WMF/MWKArticle.h>
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const WMFTimeBeforeDisplayingLastReadArticle = 60 * 60 * 24; //24 hours

@interface WMFContinueReadingContentSource ()

@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;

@end

@implementation WMFContinueReadingContentSource

- (instancetype)initWithUserDataStore:(MWKDataStore *)userDataStore {
    NSParameterAssert(userDataStore);
    self = [super init];
    if (self) {
        self.userDataStore = userDataStore;
    }
    return self;
}

#pragma mark - WMFContentSource

- (void)startUpdating {
}

- (void)stopUpdating {
}

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    NSURL *lastRead = [[NSUserDefaults wmf] wmf_openArticleURL] ?: self.userDataStore.historyList.mostRecentEntry.URL;

    NSDate *resignActiveDate = [[NSUserDefaults wmf] wmf_appResignActiveDate];

    BOOL shouldShowContinueReading = lastRead &&
                                     fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeDisplayingLastReadArticle;

    NSURL *continueReadingURL = [WMFContentGroup continueReadingContentGroupURL];
    [moc performBlock:^{
        WMFContentGroup *group = [moc contentGroupForURL:continueReadingURL];
        if (!shouldShowContinueReading) {
            if (group) {
                [moc removeContentGroup:group];
            }
            if (completion) {
                completion();
            }
            return;
        }

        NSURL *savedURL = (NSURL *)group.contentPreview;

        if ([savedURL isEqual:lastRead]) {
            if (completion) {
                completion();
            }
            return;
        }

        WMFArticle *userData = [moc fetchArticleWithURL:lastRead];

        if (userData == nil) {
            if (completion) {
                completion();
            }
            return;
        }

        [moc fetchOrCreateGroupForURL:continueReadingURL
                               ofKind:WMFContentGroupKindContinueReading
                              forDate:userData.viewedDate
                          withSiteURL:nil
                    associatedContent:nil
                   customizationBlock:^(WMFContentGroup *_Nonnull group) {
                       group.contentPreview = lastRead;
                   }];

        if (completion) {
            completion();
        }
    }];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindContinueReading];
}

@end

NS_ASSUME_NONNULL_END
