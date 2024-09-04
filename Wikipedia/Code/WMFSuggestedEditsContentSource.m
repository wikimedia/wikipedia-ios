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
                                                          // Image Recommendations Business Logic:
                                                          // Do not show suggested edits option if users have < 50 edits or they have VoiceOver on.

                                                          BOOL isEligibleForImageRecommendations = (user && user.editCount > 50 && !user.isBlocked && !UIAccessibilityIsVoiceOverRunning());

                                                          if ([self isEligibleForAltText:user] || isEligibleForImageRecommendations) {
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

- (BOOL)isEligibleForAltText:(WMFCurrentlyLoggedInUser *)user {
    NSString *applanguage = self.dataStore.languageLinkController.appLanguage.languageCode;
    BOOL enableAltTextExperimentForEN = [[WMFDeveloperSettingsDataController shared] enableAltTextExperimentForEN];
    NSSet *targetWikisForAltText = enableAltTextExperimentForEN ? [NSSet setWithObjects:@"pt", @"es", @"fr", @"zh", @"en", nil] : [NSSet setWithObjects:@"pt", @"es", @"fr", @"zh", nil];
    BOOL appLanguageIsTarget = [targetWikisForAltText containsObject:applanguage];

    // Alt text Experiment Business Logic:
    // logged in users for target wikis, bypass minimum edit count, before Oct 21st

    if (@available(iOS 16.0, *)) {
        return (user && !user.isBlocked && appLanguageIsTarget && !UIAccessibilityIsVoiceOverRunning() && self.shouldAltTextExperimentBeActive && self.isDeviceIPhone);
    }
    return NO;
}

- (BOOL)isDeviceIPhone {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
}

- (BOOL)shouldAltTextExperimentBeActive {
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:2024];
    [dateComponents setMonth:10];
    [dateComponents setDay:21];

    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *experimentDate = [calendar dateFromComponents:dateComponents];

    NSDate *currentDate = [NSDate date];

    if ([currentDate compare:experimentDate] == NSOrderedDescending) {
        return NO;
    }
    return YES;
}

- (void)removeAllContentInManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindSuggestedEdits];
}

- (NSURL *)appLanguageSiteURL {
    return self.dataStore.languageLinkController.appLanguage.siteURL;
}

@end
