#import "WMFAnnouncementsContentSource.h"
#import "WMFAnnouncementsFetcher.h"
#import "WMFAnnouncement.h"
#import <WMF/WMF-Swift.h>

#define ADD_TEST_ANNOUNCEMENT 0

@interface WMFAnnouncementsContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (readwrite, nonatomic, strong) WMFAnnouncementsFetcher *fetcher;

@end

@implementation WMFAnnouncementsContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL {
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
    }
    return self;
}

#pragma mark - Accessors

- (WMFAnnouncementsFetcher *)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[WMFAnnouncementsFetcher alloc] init];
    }
    return _fetcher;
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
}

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[NSDate date] inManagedObjectContext:moc force:force addNewContent:NO completion:completion];
}

- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force addNewContent:(BOOL)shouldAddNewContent completion:(nullable dispatch_block_t)completion {
#if DEBUG && ADD_TEST_ANNOUNCEMENT
    NSMutableArray *array = [NSMutableArray array];
    NSError *error = nil;
    WMFAnnouncement *fakeAnnouncement = [MTLJSONAdapter modelOfClass:[WMFAnnouncement class] fromJSONDictionary:@{@"id": @"test2", @"start_time":@"2017-11-27T00:00:00Z", @"end_time": @"2017-12-31T00:00:00Z", @"text": @"Hi reader in the U.S., it seems you use Wikipedia a lot; I think that’s great and hope you find it useful. It’s a little awkward to ask, but today we need your help. We depend on donations averaging $15, but fewer than 1% of readers choose to give. If you donate just $3, you would help keep Wikipedia thriving for years. That’s right, the price of a cup of coffee is all I ask. Please take a minute to keep Wikipedia growing. Thank you. — Jimmy Wales, Wikipedia Founder", @"action": @{@"title": @"Donate today", @"url": @"https://donate.wikimedia.org/?uselang=en&utm_medium=WikipediaAppFeed&utm_campaign=iOS&utm_source=app_201712_6C_control"}} error:&error];
    if (fakeAnnouncement) {
        [array addObject:fakeAnnouncement];
    } else {
        DDLogError(@"%@", error);
    }
    [self saveAnnouncements:array
     inManagedObjectContext:moc
                 completion:^{
                     [self updateVisibilityOfAnnouncementsInManagedObjectContext:moc addNewContent:shouldAddNewContent];
                     if (completion) {
                         completion();
                     }
                 }];
#else
    if ([[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate] == nil) {
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
#endif

}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc addNewContent:(BOOL)shouldAddNewContent {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindAnnouncement];
}

- (void)saveAnnouncements:(NSArray<WMFAnnouncement *> *)announcements inManagedObjectContext:(NSManagedObjectContext *)moc completion:(nullable dispatch_block_t)completion {
    [moc performBlock:^{
        [announcements enumerateObjectsUsingBlock:^(WMFAnnouncement *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {

            NSURL *URL = [WMFContentGroup announcementURLForSiteURL:self.siteURL identifier:obj.identifier];
            WMFContentGroup *group = [moc fetchOrCreateGroupForURL:URL
                                                            ofKind:WMFContentGroupKindAnnouncement
                                                           forDate:[NSDate date]
                                                       withSiteURL:self.siteURL
                                                 associatedContent:nil
                                                customizationBlock:^(WMFContentGroup * _Nonnull group) {
                                                    group.contentPreview = obj;
                                                }];
            [group updateVisibility];
        }];

        if (completion) {
            completion();
        }
    }];
}

- (void)updateVisibilityOfNotificationAnnouncementsInManagedObjectContext:(NSManagedObjectContext *)moc addNewContent:(BOOL)shouldAddNewContent {
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionLessThan:10]) {
        return;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults wmf_userDefaults];

    if (!userDefaults.wmf_didShowThemeCardInFeed) {
        NSURL *themeContentGroupURL = [WMFContentGroup themeContentGroupURL];
        [moc fetchOrCreateGroupForURL:themeContentGroupURL ofKind:WMFContentGroupKindTheme forDate:[NSDate date] withSiteURL:self.siteURL associatedContent:nil customizationBlock:NULL];
        userDefaults.wmf_didShowThemeCardInFeed = YES;
    }
}

- (void)updateVisibilityOfAnnouncementsInManagedObjectContext:(NSManagedObjectContext *)moc addNewContent:(BOOL)shouldAddNewContent {
    [self updateVisibilityOfNotificationAnnouncementsInManagedObjectContext:moc addNewContent:shouldAddNewContent];

    //Only make these visible for previous users of the app
    //Meaning a new install will only see these after they close the app and reopen
    if ([[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate] == nil) {
        return;
    }

    [moc enumerateContentGroupsOfKind:WMFContentGroupKindAnnouncement
                            withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                [group updateVisibility];
                            }];
}

@end
