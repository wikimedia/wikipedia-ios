#import "WMFSuggestedEditsContentSource.h"
#import <WMF/WMF-Swift.h>

@interface WMFSuggestedEditsContentSource ()

@property (readwrite, nonatomic) MWKDataStore *dataStore;

@end

@implementation WMFSuggestedEditsContentSource

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

- (void)loadNewContentInManagedObjectContext:(nonnull NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    
    // TODO: Fetch user edit count, image recommendations, user login state, blocked state.
    
    // TODO: if edit count > 50, wiki has image recommendations to review, user is logged in, and user is not blocked (do we need to worry about page protection?)
    NSURL *URL = [WMFContentGroup suggestedEditsURL];
    [moc fetchOrCreateGroupForURL:URL
                                                    ofKind:WMFContentGroupKindSuggestedEdits
                                                   forDate:[NSDate date]
                                               withSiteURL:self.appLanguageSiteURL
                                         associatedContent:nil
                                        customizationBlock:nil];
    
    completion();
    // else
    //[self removeAllContentInManagedObjectContext:moc];
    // end if
}

- (void)removeAllContentInManagedObjectContext:(nonnull NSManagedObjectContext *)moc { 
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindSuggestedEdits];
}

- (NSURL *)appLanguageSiteURL {
    return self.dataStore.languageLinkController.appLanguage.siteURL;
}

@end
