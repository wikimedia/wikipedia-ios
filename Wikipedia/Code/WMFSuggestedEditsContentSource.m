#import "WMFSuggestedEditsContentSource.h"
#import <WMF/WMF-Swift.h>
@import WMFData;

@interface WMFSuggestedEditsContentSource ()

@property (readwrite, nonatomic) MWKDataStore *dataStore;
@property (readwrite, nonatomic, strong) WMFGrowthTasksDataController *growthTasksDataController;

@end

@implementation WMFSuggestedEditsContentSource

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        NSString *languageCode = dataStore.languageLinkController.appLanguage.languageCode;
        self.growthTasksDataController = [[WMFGrowthTasksDataController alloc] initWithLanguageCode:languageCode];
    }
    return self;
}

- (void)loadNewContentInManagedObjectContext:(nonnull NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {

    [moc performBlock:^{
        // First delete old card
        [self removeAllContentInManagedObjectContext:moc];
        
        NSURL *appLanguageSiteURL = self.dataStore.languageLinkController.appLanguage.siteURL;
        WMFAuthenticationManager *authManager = self.dataStore.authenticationManager;

        if (!appLanguageSiteURL) {
            completion();
            return;
        }
        
        if (!authManager.authStateIsPermanent) {
            completion();
            return;
        }
            
        WMFCurrentUser *user = [self.dataStore.authenticationManager userWithSiteURL:appLanguageSiteURL];
        
        // Image Recommendations Business Logic:
        // Do not show suggested edits option if users have < 50 edits or they have VoiceOver on.

        BOOL isEligibleForImageRecommendations = (user && user.editCount > 50 && !user.isBlocked && !UIAccessibilityIsVoiceOverRunning());

        if (isEligibleForImageRecommendations) {
            [self.growthTasksDataController hasImageRecommendationsWithCompletion:^(BOOL hasRecommendations) {
                if (hasRecommendations) {
                    NSURL *URL = [WMFContentGroup suggestedEditsURLForSiteURL:appLanguageSiteURL];
                    
                    [moc performBlock:^{
                        [moc fetchOrCreateGroupForURL:URL ofKind:WMFContentGroupKindSuggestedEdits forDate:[NSDate date] withSiteURL:appLanguageSiteURL associatedContent:nil customizationBlock:nil];
                        completion();
                    }];
                }
            }];
        } else {
            completion();
        }
    }];
}

- (BOOL)isDeviceIPhone {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
}

- (void)removeAllContentInManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindSuggestedEdits];
}

- (NSURL *)appLanguageSiteURL {
    return self.dataStore.languageLinkController.appLanguage.siteURL;
}

@end
