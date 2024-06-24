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
        [self.dataStore.authenticationManager getLoggedInUserFor:appLanguageSiteURL
                                                      completion:^(WMFCurrentlyLoggedInUser *user) {
                                                          if ((user && user.editCount > 50 && !user.isBlocked && !UIAccessibilityIsVoiceOverRunning()) || WMFFeatureFlags.forceImageRecommendationsExploreCard) {

                                                              [self.growthTasksDataController hasImageRecommendationsWithCompletion:^(BOOL hasRecommendations) {
                                                                  if (hasRecommendations) {
                                                                      NSURL *URL = [WMFContentGroup suggestedEditsURLForSiteURL:appLanguageSiteURL];

                                                                      [moc fetchOrCreateGroupForURL:URL ofKind:WMFContentGroupKindSuggestedEdits forDate:[NSDate date] withSiteURL:appLanguageSiteURL associatedContent:nil customizationBlock:nil];
                                                                  }

                                                                  completion();
                                                              }];
                                                          } else {
                                                              completion();
                                                          }
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
