#import "WMFAnnouncementsContentSource.h"
#import "WMFAnnouncementsFetcher.h"
#import "WMFAnnouncement.h"
#import <WMF/WMF-Swift.h>

@interface WMFAnnouncementsContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (readwrite, nonatomic, strong) WMFAnnouncementsFetcher *fetcher;
@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;

@end

@implementation WMFAnnouncementsContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL userDataStore:(MWKDataStore *)userDataStore {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.userDataStore = userDataStore;
        self.fetcher = [[WMFAnnouncementsFetcher alloc] initWithSession: userDataStore.session configuration: userDataStore.configuration];
    }
    return self;
}

#pragma mark - Accessors

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
}

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[NSDate date] inManagedObjectContext:moc force:force addNewContent:NO completion:completion];
}

- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force addNewContent:(BOOL)shouldAddNewContent completion:(nullable dispatch_block_t)completion {
    if ([[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate] == nil) {
        [moc performBlock:^{
            [self updateVisibilityOfAnnouncementsInManagedObjectContext:moc addNewContent:shouldAddNewContent];
            if (completion) {
                completion();
            }
        }];
        return;
    }
    [self.fetcher fetchAnnouncementsForURL:self.siteURL
        force:force
        failure:^(NSError *_Nonnull error) {
            [moc performBlock:^{
                [self updateVisibilityOfAnnouncementsInManagedObjectContext:moc addNewContent:shouldAddNewContent];
                if (completion) {
                    completion();
                }
            }];
        }
        success:^(NSArray<WMFAnnouncement *> *announcements) {
            [self saveAnnouncements:announcements
                inManagedObjectContext:moc
                            completion:^{
                                [self updateVisibilityOfAnnouncementsInManagedObjectContext:moc addNewContent:shouldAddNewContent];
                                if (completion) {
                                    completion();
                                }
                            }];
        }];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc addNewContent:(BOOL)shouldAddNewContent {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindAnnouncement];
}

- (void)saveAnnouncements:(NSArray<WMFAnnouncement *> *)announcements inManagedObjectContext:(NSManagedObjectContext *)moc completion:(nullable dispatch_block_t)completion {
    [moc performBlock:^{
        BOOL isLoggedIn = self.fetcher.session.isAuthenticated;
        [announcements enumerateObjectsUsingBlock:^(WMFAnnouncement *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            NSURL *URL = [WMFContentGroup announcementURLForSiteURL:self.siteURL identifier:obj.identifier];
            WMFContentGroup *group = [moc fetchOrCreateGroupForURL:URL
                                                            ofKind:WMFContentGroupKindAnnouncement
                                                           forDate:[NSDate date]
                                                       withSiteURL:self.siteURL
                                                 associatedContent:nil
                                                customizationBlock:^(WMFContentGroup *_Nonnull group) {
                                                    group.contentPreview = obj;
                                                    group.placement = obj.placement;
                                                }];
            [group updateVisibilityForUserIsLoggedIn:isLoggedIn];
        }];

        [[WMFSurveyAnnouncementsController shared] setAnnouncements:announcements forSiteURL:self.siteURL dataStore:self.userDataStore];
        if (completion) {
            completion();
        }
    }];
}

- (void)updateVisibilityOfNotificationAnnouncementsInManagedObjectContext:(NSManagedObjectContext *)moc addNewContent:(BOOL)shouldAddNewContent {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //Only make these visible for previous users of the app
    //Meaning a new install will only see these after they close the app and reopen
    if ([userDefaults wmf_appResignActiveDate] == nil) {
        return;
    }

    [moc removeAllContentGroupsOfKind:WMFContentGroupKindTheme];

    if (moc.wmf_isSyncRemotelyEnabled && !NSUserDefaults.standardUserDefaults.wmf_didShowReadingListCardInFeed && !self.fetcher.session.isAuthenticated) {
        NSURL *readingListContentGroupURL = [WMFContentGroup readingListContentGroupURLWithLanguageVariantCode:self.siteURL.wmf_languageVariantCode];
        [moc fetchOrCreateGroupForURL:readingListContentGroupURL ofKind:WMFContentGroupKindReadingList forDate:[NSDate date] withSiteURL:self.siteURL associatedContent:nil customizationBlock:NULL];
        NSUserDefaults.standardUserDefaults.wmf_didShowReadingListCardInFeed = YES;
    } else {
        [moc removeAllContentGroupsOfKind:WMFContentGroupKindReadingList];
    }

    // Workaround for the great fundraising mystery of 2019: https://phabricator.wikimedia.org/T247554
    // TODO: Further investigate the root cause before adding the 2020 fundraising banner: https://phabricator.wikimedia.org/T247976
    //also deleting IOSSURVEY20 because we want to bypass persistence and only consider in online mode
    NSArray *announcements = [moc contentGroupsOfKind:WMFContentGroupKindAnnouncement];
    for (WMFContentGroup *announcement in announcements) {
        if (![announcement.key containsString:@"FUNDRAISING19"] && ![announcement.key containsString:@"IOSSURVEY20"]) {
            continue;
        }
        [moc deleteObject:announcement];
    }
}

- (void)updateVisibilityOfAnnouncementsInManagedObjectContext:(NSManagedObjectContext *)moc addNewContent:(BOOL)shouldAddNewContent {
    [self updateVisibilityOfNotificationAnnouncementsInManagedObjectContext:moc addNewContent:shouldAddNewContent];

    //Only make these visible for previous users of the app
    //Meaning a new install will only see these after they close the app and reopen
    if ([[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate] == nil) {
        return;
    }
    BOOL isLoggedIn = self.fetcher.session.isAuthenticated;
    [moc enumerateContentGroupsOfKind:WMFContentGroupKindAnnouncement
                            withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                [group updateVisibilityForUserIsLoggedIn:isLoggedIn];
                            }];
}

@end
