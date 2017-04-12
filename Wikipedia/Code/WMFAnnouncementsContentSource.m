#import "WMFAnnouncementsContentSource.h"
#import "WMFAnnouncementsFetcher.h"
#import "WMFAnnouncement.h"
#import <WMF/WMF-Swift.h>

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

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(dispatch_block_t)completion {

    [self.fetcher fetchAnnouncementsForURL:self.siteURL
        force:force
        failure:^(NSError *_Nonnull error) {
            [self updateVisibilityOfAnnouncementsInManagedObjectContext:moc];
            if (completion) {
                completion();
            }
        }
        success:^(NSArray<WMFAnnouncement *> *announcements) {
            [self saveAnnouncements:announcements
             inManagedObjectContext:moc
                         completion:^{
                             [self updateVisibilityOfAnnouncementsInManagedObjectContext:moc];
                             if (completion) {
                                 completion();
                             }
                         }];
        }];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindAnnouncement];
}

- (void)saveAnnouncements:(NSArray<WMFAnnouncement *> *)announcements inManagedObjectContext:(NSManagedObjectContext *)moc completion:(nullable dispatch_block_t)completion {

    [announcements enumerateObjectsUsingBlock:^(WMFAnnouncement *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {

        NSURL *URL = [WMFContentGroup announcementURLForSiteURL:self.siteURL identifier:obj.identifier];
        WMFContentGroup *group = [moc fetchOrCreateGroupForURL:URL
                                                        ofKind:WMFContentGroupKindAnnouncement
                                                       forDate:[NSDate date]
                                                   withSiteURL:self.siteURL
                                             associatedContent:@[obj]
                                            customizationBlock:NULL];
        //Make these visible immediately for previous users
        if ([[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate] != nil) {
            [group updateVisibility];
        }
    }];

    if (completion) {
        completion();
    }
}

- (void)updateVisibilityOfAnnouncementsInManagedObjectContext:(NSManagedObjectContext *)moc {
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
