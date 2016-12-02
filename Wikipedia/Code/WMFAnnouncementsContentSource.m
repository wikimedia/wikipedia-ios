
#import "WMFAnnouncementsContentSource.h"
#import "WMFAnnouncementsFetcher.h"
#import "WMFAnnouncement.h"
#import "WMFContentGroupDataStore.h"
#import <WMFModel/WMFModel-Swift.h>

@interface WMFAnnouncementsContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;
@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFAnnouncementsFetcher *fetcher;

@end

@implementation WMFAnnouncementsContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore {
    NSParameterAssert(siteURL);
    NSParameterAssert(contentStore);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.contentStore = contentStore;
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

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {

    [self.fetcher fetchAnnouncementsForURL:self.siteURL
        force:force
        failure:^(NSError *_Nonnull error) {
            [self updateVisibilityOfAnnouncements];
            if (completion) {
                completion();
            }
        }
        success:^(NSArray<WMFAnnouncement *> *announcements) {
            [self saveAnnouncements:announcements
                         completion:^{
                             [self updateVisibilityOfAnnouncements];
                             if (completion) {
                                 completion();
                             }
                         }];
        }];
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindAnnouncement];
}

- (void)saveAnnouncements:(NSArray<WMFAnnouncement *> *)announcements completion:(nullable dispatch_block_t)completion {

    [announcements enumerateObjectsUsingBlock:^(WMFAnnouncement *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSURL *URL = [WMFContentGroup announcementURLForSiteURL:self.siteURL identifier:obj.identifier];
        WMFContentGroup *group = [self.contentStore fetchOrCreateGroupForURL:URL
                                                                      ofKind:WMFContentGroupKindAnnouncement
                                                                     forDate:[NSDate date]
                                                                 withSiteURL:self.siteURL
                                                           associatedContent:@[obj]
                                                          customizationBlock:^(WMFContentGroup *_Nonnull group){

                                                          }];
        //Make these visible immediately for previous users
        if ([[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate] != nil) {
            [group updateVisibility];
        }
    }];

    if (completion) {
        completion();
    }
}

- (void)updateVisibilityOfAnnouncements {
    //Only make these visible for previous users of the app
    //Meaning a new install will only see these after they close the app and reopen
    if ([[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate] == nil) {
        return;
    }

    [self.contentStore enumerateContentGroupsOfKind:WMFContentGroupKindAnnouncement
                                          withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                              [group updateVisibility];
                                          }];
}

@end
