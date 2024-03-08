#import "WMFSuggestedEditsContentSource.h"
#import <WMF/WMF-Swift.h>

@interface WMFSuggestedEditsContentSource ()

@property (readwrite, nonatomic) MWKDataStore *dataStore;
@property (readwrite, nonatomic, strong) WMFCurrentlyLoggedInUserFetcher *fetcher;

@end

@implementation WMFSuggestedEditsContentSource

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        self.fetcher = [[WMFCurrentlyLoggedInUserFetcher alloc] initWithSession: dataStore.session configuration: dataStore.configuration];
    }
    return self;
}

- (void)loadNewContentInManagedObjectContext:(nonnull NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    
    // First delete old card
    [self removeAllContentInManagedObjectContext:moc];
    
    NSURL *appLanguageSiteURL = self.dataStore.languageLinkController.appLanguage.siteURL;
    
    if (!appLanguageSiteURL) {
        completion();
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dataStore.authenticationManager getLoggedInUserFor:appLanguageSiteURL completion:^(WMFCurrentlyLoggedInUser *user) {
            
            if (user) {
                if (user.editCount > 50 && !user.isBlocked) {
                    NSURL *URL = [WMFContentGroup suggestedEditsURL];
                    [moc fetchOrCreateGroupForURL:URL ofKind:WMFContentGroupKindSuggestedEdits forDate:[NSDate date] withSiteURL:appLanguageSiteURL associatedContent:nil customizationBlock:nil];
                }
            }
            
            completion();
        }];
    });
    
}

- (void)removeAllContentInManagedObjectContext:(nonnull NSManagedObjectContext *)moc { 
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindSuggestedEdits];
}

- (NSURL *)appLanguageSiteURL {
    return self.dataStore.languageLinkController.appLanguage.siteURL;
}

@end
