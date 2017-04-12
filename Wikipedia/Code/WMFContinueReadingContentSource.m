#import "WMFContinueReadingContentSource.h"
#import "MWKDataStore.h"
#import "MWKHistoryEntry.h"
#import "MWKArticle.h"
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
    NSURL *lastRead = [[NSUserDefaults wmf_userDefaults] wmf_openArticleURL];

    NSDate *resignActiveDate = [[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate];

    BOOL shouldShowContinueReading = lastRead &&
                                     fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeDisplayingLastReadArticle;

    NSURL *continueReadingURL = [WMFContentGroup continueReadingContentGroupURL];
    [moc performBlock:^{
        WMFContentGroup * group = [moc contentGroupForURL:continueReadingURL];
        if (!shouldShowContinueReading) {
            if (group) {
                [moc removeContentGroup:group];
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
        
        WMFArticle *userData = [moc fetchArticleWithURL:lastRead];
        
        if (userData == nil) {
            if (completion) {
                completion();
            }
            return;
        }
        
        WMF_TECH_DEBT_TODO(Remove this in a later version.A preview will always be available)
        WMFArticle *article = [moc fetchArticleWithURL:lastRead];
        if (!article) {
            MWKArticle *mwkArticle = [self.userDataStore articleWithURL:lastRead];
            NSParameterAssert(mwkArticle);
            [article updateWithMWKArticle:mwkArticle];
        }
        
        [moc fetchOrCreateGroupForURL:continueReadingURL ofKind:WMFContentGroupKindContinueReading forDate:userData.viewedDate withSiteURL:nil associatedContent:@[lastRead] customizationBlock:NULL];
        
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
