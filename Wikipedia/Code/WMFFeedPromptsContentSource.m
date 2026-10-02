#import "WMFFeedPromptsContentSource.h"
#import <WMF/WMF-Swift.h>

/*
 The app does not show announcement cards any more. This content source keeps two other jobs:
 it gets the MediaWiki banner opt-in for the donate feature when the user logs in, and it adds
 or removes the reading list card in the Explore feed. It also deletes the announcement groups
 that earlier app versions saved.
 */

@interface WMFFeedPromptsContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;
@property (readonly, nonatomic, assign) BOOL isLoggedIn;

@end

@implementation WMFFeedPromptsContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL userDataStore:(MWKDataStore *)userDataStore {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.userDataStore = userDataStore;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userWasLoggedIn:)
                                                     name:[WMFAuthenticationManager didLogInNotification]
                                                   object:nil];
    }

    return self;
}

#pragma mark - Getters and Setters

- (BOOL)isLoggedIn {
    return self.userDataStore.authenticationManager.authStateIsPermanent;
}

#pragma mark - Notifications

- (void)userWasLoggedIn:(NSNotification *)note {
    [self fetchMediaWikiBannerOptInForSiteURL:self.siteURL];
}

#pragma mark - WMFContentSource

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindAnnouncement];
}

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[NSDate date] inManagedObjectContext:moc force:force addNewContent:NO completion:completion];
}

- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force addNewContent:(BOOL)shouldAddNewContent completion:(nullable dispatch_block_t)completion {
    [moc performBlock:^{
        [self updateFeedCardsInManagedObjectContext:moc];
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Feed Cards

- (void)updateFeedCardsInManagedObjectContext:(NSManagedObjectContext *)moc {
    // Only make these visible for previous users of the app.
    // A new install only sees them after the user closes the app and opens it again.
    if ([[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate] == nil) {
        return;
    }

    [moc removeAllContentGroupsOfKind:WMFContentGroupKindTheme];
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindAnnouncement];

    if (moc.wmf_isSyncRemotelyEnabled && !NSUserDefaults.standardUserDefaults.wmf_didShowReadingListCardInFeed && !self.isLoggedIn) {
        NSURL *readingListContentGroupURL = [WMFContentGroup readingListContentGroupURLWithLanguageVariantCode:self.siteURL.wmf_languageVariantCode];
        [moc fetchOrCreateGroupForURL:readingListContentGroupURL ofKind:WMFContentGroupKindReadingList forDate:[NSDate date] withSiteURL:self.siteURL associatedContent:nil customizationBlock:NULL];
        NSUserDefaults.standardUserDefaults.wmf_didShowReadingListCardInFeed = YES;
    } else {
        [moc removeAllContentGroupsOfKind:WMFContentGroupKindReadingList];
    }
}

@end
