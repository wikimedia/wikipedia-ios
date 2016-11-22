
#import "WMFAnnouncementsContentSource.h"
#import "WMFAnnouncementsFetcher.h"
#import "WMFAnnouncement.h"
#import "WMFContentGroupDataStore.h"
#import "WMFContentGroup.h"
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

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion{
    
    [self.fetcher fetchAnnouncementsForURL:self.siteURL force:force failure:^(NSError * _Nonnull error) {
        [self updateVisibilityOfAnnouncements];
        if(completion){
            completion();
        }
    } success:^(NSArray<WMFAnnouncement *> *announcements) {
        [self saveAnnouncements:announcements completion:^{
            [self updateVisibilityOfAnnouncements];
            if(completion){
                completion();
            }
        }];
    }];
    
}

- (void)removeAllContent{
    [self.contentStore removeAllContentGroupsOfKind:[WMFAnnouncementContentGroup kind]];
}


- (void)saveAnnouncements:(NSArray<WMFAnnouncement *> *)announcements completion:(nullable dispatch_block_t)completion{
    
    [announcements enumerateObjectsUsingBlock:^(WMFAnnouncement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        WMFAnnouncementContentGroup* group = [self groupForAnnouncement:obj];
        //Make these visible immediately for previous users
        if([[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate] != nil){
            [group updateVisibility];
        }
        [self.contentStore addContentGroup:group associatedContent:@[obj]];
    }];
    [self.contentStore notifyWhenWriteTransactionsComplete:^{
        if(completion){
            completion();
        }
    }];
}

- (WMFAnnouncementContentGroup *)groupForAnnouncement:(WMFAnnouncement *)announcement {
    
    NSURL* URL = [WMFAnnouncementContentGroup urlForSiteURL:self.siteURL identifier:announcement.identifier];
    
    WMFAnnouncementContentGroup* foundGroup = [(WMFAnnouncementContentGroup*)[self.contentStore contentGroupForURL:URL] copy];
    WMFAnnouncementContentGroup* group = [[WMFAnnouncementContentGroup alloc] initWithDate:[NSDate date] visibilityStartDate:announcement.startTime visibilityEndDate:announcement.endTime siteURL:self.siteURL identifier:announcement.identifier];;
    
    if(foundGroup != nil){
        if(foundGroup.wasDismissed){
            [group markDismissed];
        }
        if([foundGroup isVisible]){
            [group updateVisibility];
        }
    }
    
    return group;
}


- (void)updateVisibilityOfAnnouncements{
    //Only make these visible for previous users of the app
    //Meaning a new install will only see these after they close the app and reopen
    if([[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate] == nil){
        return;
    }

    NSMutableArray<WMFAnnouncementContentGroup*>* groups = [NSMutableArray array];
    [self.contentStore enumerateContentGroupsOfKind:[WMFAnnouncementContentGroup kind] withBlock:^(WMFContentGroup * _Nonnull group, BOOL * _Nonnull stop) {
        
        WMFAnnouncementContentGroup* aGroup = (WMFAnnouncementContentGroup*)group;
        if([aGroup updateVisibility]){
            [groups addObject:aGroup];
        }
    }];
    
    [groups enumerateObjectsUsingBlock:^(WMFAnnouncementContentGroup * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.contentStore addContentGroup:obj associatedContent:[self.contentStore contentForContentGroup:obj]];
    }];
    
}



@end
