#import <WMF/WMFContinueReadingContentSource.h>
#import <WMF/MWKDataStore.h>
#import <WMF/WMF-Swift.h>
@import WMFData;

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const WMFTimeBeforeDisplayingLastReadArticle = 60 * 60 * 24; // 24 hours

@interface WMFContinueReadingContentSource ()

@property (readwrite, nonatomic, weak) MWKDataStore *userDataStore;

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

    [moc performBlock:^{
        // Check Home flags before the lastRead guard so that stale Continue Reading
        // groups are removed even when the user has no reading history.
        // Read through WMFDeveloperSettingsDataController so the JSON-encoded Data
        // values stored by WMFUserDefaultsStore are decoded correctly — NSUserDefaults
        // boolForKey: returns NO for those.
        WMFDeveloperSettingsDataController *devSettings = WMFDeveloperSettingsDataController.shared;
        if (WMFHomeDataController.shared.isHomeTabGroupB || devSettings.enableHomePhase2) {
            NSArray<WMFContentGroup *> *existingGroups = [moc contentGroupsOfKind:WMFContentGroupKindContinueReading];
            for (WMFContentGroup *group in existingGroups) {
                [moc removeContentGroup:group];
            }
            if (completion) {
                completion();
            }
            return;
        }

        NSURL *lastRead = [moc wmf_openArticleURL] ?: moc.mostRecentlyReadArticle.URL;

        if (!lastRead) {
            if (completion) {
                completion();
            }
            return;
        }

        NSDate *resignActiveDate = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];

        BOOL shouldShowContinueReading = fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeDisplayingLastReadArticle || force;

        NSArray<WMFContentGroup *> *groups = [moc contentGroupsOfKind:WMFContentGroupKindContinueReading];
        if (!shouldShowContinueReading) {
            if (groups.count > 0) {
                for (WMFContentGroup *group in groups) {
                    [moc removeContentGroup:group];
                }
            }
            if (completion) {
                completion();
            }
            return;
        }

        NSURL *savedURL = (NSURL *)groups.firstObject.contentPreview;

        if ([savedURL isEqual:lastRead]) {
            if (completion) {
                completion();
            }
            return;
        }

        WMFArticle *userData = [moc fetchArticleWithURL:lastRead];
        NSNumber *ns = [userData namespaceNumber];
        if (userData == nil || userData.isExcludedFromFeed || ns == nil || ns.integerValue != 0) {
            if (completion) {
                completion();
            }
            return;
        }

        for (WMFContentGroup *group in groups) {
            [moc removeContentGroup:group];
        }

        NSURL *continueReadingURL = [WMFContentGroup continueReadingContentGroupURLForArticleURL:lastRead];
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
