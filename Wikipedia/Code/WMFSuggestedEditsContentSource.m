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
        NSString *applanguage = self.dataStore.languageLinkController.appLanguage.languageCode;
        BOOL enableAltTextExperiment = [[WKDeveloperSettingsDataController shared] enableAltTextExperiment];
        NSSet *targetWikisForAltText = [NSSet setWithObjects:@"pt", @"es", @"fr", @"zh", nil];
        BOOL appLanguageIsTarget = [targetWikisForAltText containsObject:applanguage];

        [self.dataStore.authenticationManager getLoggedInUserFor:appLanguageSiteURL
                                                      completion:^(WMFCurrentlyLoggedInUser *user) {

            // Alt text Experiment Business Logic - for target wikis, bypass minimum edit count
            BOOL altTextExperiment = (enableAltTextExperiment && appLanguageIsTarget && !user.isBlocked && !UIAccessibilityIsVoiceOverRunning());
            // Image Recommendations Business Logic:
            // Do not show suggested edits option if users have < 50 edits or they have VoiceOver on.
            BOOL regularImageRecommendations = (user && user.editCount > 50 && !user.isBlocked && !UIAccessibilityIsVoiceOverRunning());

            if (altTextExperiment || regularImageRecommendations) {

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
