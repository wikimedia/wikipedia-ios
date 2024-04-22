#import "WMFSuggestedEditsContentSource.h"
#import <WMF/WMF-Swift.h>
@import WKData;

@interface WMFSuggestedEditsContentSource ()

@property (readwrite, nonatomic) MWKDataStore *dataStore;
@property (readwrite, nonatomic, strong) WKGrowthTasksDataController *growthTasksDataController;

@end

@implementation WMFSuggestedEditsContentSource

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        NSString *languageCode = dataStore.languageLinkController.appLanguage.languageCode;
        self.growthTasksDataController = [[WKGrowthTasksDataController alloc] initWithLanguageCode:languageCode];
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
        
        WMFTaskGroup *group = [WMFTaskGroup new];
        
        __block WMFCurrentlyLoggedInUser *currentUser = nil;
        __block BOOL hasImageRecommendations = NO;
        
        [group enter];
        [self.dataStore.authenticationManager getLoggedInUserFor:appLanguageSiteURL completion:^(WMFCurrentlyLoggedInUser *user) {
            currentUser = user;
            [group leave];
        }];
        
        [group enter];
        [self.growthTasksDataController hasImageRecommendationsWithCompletion:^(BOOL hasRecommendations) {
            hasImageRecommendations = hasRecommendations;
            [group leave];
        }];
        
        [group waitInBackgroundWithCompletion:^{
            if (currentUser) {
                if ((currentUser.editCount > 50 && !currentUser.isBlocked && hasImageRecommendations) || WMFFeatureFlags.forceImageRecommendationsExploreCard) {

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
