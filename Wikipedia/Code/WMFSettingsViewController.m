#import "WMFSettingsTableViewCell.h"
@import WMF;
#import "Wikipedia-Swift.h"

#import "WMFSettingsViewController.h"
#import "WMFLanguagesViewController.h"
#import "AboutViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
@import WMFData;

#pragma mark - Static URLs

NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFSettingsURLZeroFAQ = @"https://foundation.wikimedia.org/wiki/Wikipedia_Zero_App_FAQ";
static NSString *const WMFSettingsURLTerms = @"https://foundation.wikimedia.org/wiki/Terms_of_Use/en";
static NSString *const WMFSettingsURLRate = @"itms-apps://itunes.apple.com/app/id324715238";
static NSString *const WMFSettingsURLDonation = @"https://donate.wikimedia.org/?utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=appmenu&app_version=<app-version>&uselang=<langcode>";

@interface WMFSettingsViewController () <UITableViewDelegate, UITableViewDataSource, WMFAccountViewControllerDelegate>

@property (nonatomic, strong, readwrite) MWKDataStore *dataStore;

@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nullable, nonatomic) WMFAuthenticationManager *authManager;
@property (readwrite, nonatomic, strong) WMFDonateDataController *donateDataController;
@property (nullable, nonatomic, strong) WMFYearInReviewCoordinator *yirCoordinator;

@end

@implementation WMFSettingsViewController

+ (instancetype)settingsViewControllerWithDataStore:(MWKDataStore *)store theme:(WMFTheme *)theme {
    NSParameterAssert(store);
    WMFSettingsViewController *vc = [WMFSettingsViewController wmf_initialViewControllerFromClassStoryboard];
    vc.dataStore = store;
    vc.donateDataController = [WMFDonateDataController sharedInstance];
    vc.theme = theme;
    return vc;
}

#pragma mark - Setup

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];

    [self.tableView registerNib:[WMFSettingsTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFSettingsTableViewCell identifier]];
    [self.tableView registerNib:[WMFTableHeaderFooterLabelView wmf_classNib] forHeaderFooterViewReuseIdentifier:[WMFTableHeaderFooterLabelView identifier]];
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 44;
    self.tableView.sectionFooterHeight = 0;

    self.tableView.estimatedRowHeight = 52.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.authManager = self.dataStore.authenticationManager;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationBannerDidDisplayInForeground:) name:NSNotification.pushNotificationBannerDidDisplayInForeground object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userWasLoggedIn:)
                                                 name:[WMFAuthenticationManager didLogInNotification]
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userWasLoggedOut:)
                                                 name:[WMFAuthenticationManager didLogOutNotification]
                                               object:nil];

    [self setupTopSafeAreaOverlayFromObjCWithScrollView:self.tableView];
    [self applyTheme:self.theme];
}

- (void)dealloc {
    self.authManager = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [NSUserActivity wmf_makeActivityActive:[NSUserActivity wmf_settingsViewActivity]];
    [self.dataStore.remoteNotificationsController triggerLoadNotificationsWithForce:NO];
    
    if ([[WMFYearInReviewDataController dataControllerForObjectiveC] shouldShowYearInReviewSettingsItemWithCountryCode:NSLocale.currentLocale.countryCode]) {
        [[WMFDonateFunnel shared] logYearInReviewSettingsDidAppear];
    }
}

- (UIScrollView *_Nullable)scrollView {
    return self.tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadSections];

    [self configureNavigationBarFromObjC];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    [self configureNavigationBarFromObjC];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    @weakify(self);
    [coordinator animateAlongsideTransition:nil
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
                                     @strongify(self);
                                     [self calculateTopSafeAreaOverlayHeightFromObjC];
                                 }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WMFSettingsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:WMFSettingsTableViewCell.identifier forIndexPath:indexPath];

    NSArray *menuItems = [self.sections[indexPath.section] getItems];
    WMFSettingsMenuItem *menuItem = menuItems[indexPath.item];

    cell.tag = menuItem.type;
    cell.title = menuItem.title;
    [cell applyTheme:self.theme];
    if (!self.theme.colors.icon) {
        cell.iconColor = [UIColor whiteColor];
        cell.iconBackgroundColor = menuItem.iconColor;
    }
    cell.iconName = menuItem.iconName;
    cell.disclosureType = menuItem.disclosureType;
    cell.disclosureText = menuItem.disclosureText;
    [cell.disclosureSwitch setOn:menuItem.isSwitchOn];
    cell.selectionStyle = (menuItem.disclosureType == WMFSettingsMenuItemDisclosureType_Switch) ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

    if (menuItem.disclosureType != WMFSettingsMenuItemDisclosureType_Switch && menuItem.disclosureType != WMFSettingsMenuItemDisclosureType_None) {
        cell.accessibilityTraits = UIAccessibilityTraitButton;
    } else {
        cell.accessibilityTraits = UIAccessibilityTraitStaticText;
    }

    [cell.disclosureSwitch removeTarget:self
                                 action:@selector(disclosureSwitchChanged:)
                       forControlEvents:UIControlEventValueChanged];
    cell.disclosureSwitch.tag = menuItem.type;
    [cell.disclosureSwitch addTarget:self action:@selector(disclosureSwitchChanged:) forControlEvents:UIControlEventValueChanged];

    return cell;
}

- (BOOL)accessibilityPerformEscape {
    [self closeButtonPressed];
    return YES;
}

- (void)disclosureSwitchChanged:(UISwitch *)disclosureSwitch {
    WMFSettingsMenuItemType type = (WMFSettingsMenuItemType)disclosureSwitch.tag;
    [self logNavigationEventsForMenuType:type];
    [self loadSections];
}

#pragma mark - Switch tap handling

- (void)logNavigationEventsForMenuType:(WMFSettingsMenuItemType)type {

    switch (type) {
        case WMFSettingsMenuItemType_LoginAccount:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsLoginLogout];
            break;
        case WMFSettingsMenuItemType_SearchLanguage:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsLanguages];
            break;
        case WMFSettingsMenuItemType_Search:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsSearch];
            break;
        case WMFSettingsMenuItemType_ExploreFeed:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsExploreFeed];
            break;
        case WMFSettingsMenuItemType_Notifications:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsNotifications];
            break;
        case WMFSettingsMenuItemType_Appearance:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsReadingPreferences];
            break;
        case WMFSettingsMenuItemType_StorageAndSyncing:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsArticleStorageAndSyncing];
            break;
        case WMFSettingsMenuItemType_DatabasePopulation:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsReadingListDangerZone];
            break;
        case WMFSettingsMenuItemType_Support:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsSupportWikipedia];
            break;
        case WMFSettingsMenuItemType_PrivacyPolicy:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsPrivacyPolicy];
            break;
        case WMFSettingsMenuItemType_Terms:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsTermsOfUse];
            break;
        case WMFSettingsMenuItemType_RateApp:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsRateTheApp];
            break;
        case WMFSettingsMenuItemType_SendFeedback:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsHelp];
            break;
        case WMFSettingsMenuItemType_About:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsAbout];
            break;
        case WMFSettingsMenuItemType_ClearCache:
            [[WMFNavigationEventsFunnel shared] logTappedSettingsClearCachedData];
            break;
        default:
            break;
    }
}

#pragma mark - Cell tap handling

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    switch (cell.tag) {
        case WMFSettingsMenuItemType_LoginAccount:
            [self showLoginOrAccount];
            break;
        case WMFSettingsMenuItemType_SearchLanguage:
            [self showLanguages];
            break;
        case WMFSettingsMenuItemType_Search:
            [self showSearch];
            break;
        case WMFSettingsMenuItemType_ExploreFeed:
            [self showExploreFeedSettings];
            break;
        case WMFSettingsMenuItemType_Notifications:
            [self showNotifications];
            break;
        case WMFSettingsMenuItemType_YearInReview:
            [self showYearInReview];
            break;
        case WMFSettingsMenuItemType_Appearance: {
            [self showAppearance];
            break;
        }
        case WMFSettingsMenuItemType_StorageAndSyncing: {
            [self showStorageAndSyncing];
            break;
        }
        case WMFSettingsMenuItemType_DatabasePopulation: {
            [self showDatabasePopulation];
            break;
        }
        case WMFSettingsMenuItemType_Support: {
            if ([cell isKindOfClass:[WMFSettingsTableViewCell class]]) {
                WMFSettingsTableViewCell *settingsCell = (WMFSettingsTableViewCell *)cell;
                [self showDonateForCell:settingsCell];
            }
        } break;
        case WMFSettingsMenuItemType_PrivacyPolicy:
            [self wmf_navigateToURL:[NSURL URLWithString:[WMFCommonStrings privacyPolicyURLString]]];
            break;
        case WMFSettingsMenuItemType_Terms:
            [self wmf_navigateToURL:[NSURL URLWithString:WMFSettingsURLTerms]];
            break;
        case WMFSettingsMenuItemType_ZeroFAQ:
            [self wmf_navigateToURL:[NSURL URLWithString:WMFSettingsURLZeroFAQ]];
            break;
        case WMFSettingsMenuItemType_RateApp:
            [self wmf_navigateToURL:[NSURL URLWithString:WMFSettingsURLRate] useSafari:YES];
            break;
        case WMFSettingsMenuItemType_SendFeedback: {
            WMFHelpViewController *vc = [[WMFHelpViewController alloc] initWithDataStore:self.dataStore theme:self.theme];
            [self.navigationController pushViewController:vc animated:YES];
        } break;
        case WMFSettingsMenuItemType_About: {
            AboutViewController *vc = [[AboutViewController alloc] initWithTheme:self.theme];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case WMFSettingsMenuItemType_ClearCache:
            [self showClearCacheActionSheet];
            break;
        case WMFSettingsMenuItemType_DonateHistory:
            [self clearDonationHistory];
            break;
        case WMFSettingsMenuItemType_TemporaryAccount:
            [self showTemporaryAccount];
            break;
        default:
            break;
    }

    [self logNavigationEventsForMenuType:cell.tag];

    [self.tableView deselectRowAtIndexPath:indexPath
                                  animated:YES];
}

#pragma mark - Dynamic URLs

- (NSURL *)donationURL {
    NSString *url = WMFSettingsURLDonation;

    NSString *languageCode = MWKDataStore.shared.languageLinkController.appLanguage.languageCode;
    languageCode = [languageCode stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSString *appVersion = [[NSBundle mainBundle] wmf_debugVersion];
    appVersion = [appVersion stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    url = [url stringByReplacingOccurrencesOfString:@"<langcode>" withString:languageCode];
    url = [url stringByReplacingOccurrencesOfString:@"<app-version>" withString:appVersion];

    return [NSURL URLWithString:url];
}

#pragma mark - Presentation

- (void)presentViewControllerWrappedInNavigationController:(UIViewController<WMFThemeable> *)viewController {
    WMFComponentNavigationController *navVC = [[WMFComponentNavigationController alloc] initWithRootViewController:viewController modalPresentationStyle:UIModalPresentationOverFullScreen customBarBackgroundColor:nil];
    [self presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - Log in and out

- (void)showLoginOrAccount {
    NSString *userName = self.dataStore.authenticationManager.authStatePermanentUsername;
    if (userName) {
        WMFAccountViewController *accountVC = [[WMFAccountViewController alloc] init];
        accountVC.dataStore = self.dataStore;
        accountVC.delegate = self;
        [accountVC applyTheme:self.theme];
        [self.navigationController pushViewController:accountVC animated:YES];
    } else {
        WMFLoginViewController *loginVC = [WMFLoginViewController wmf_initialViewControllerFromClassStoryboard];
        [loginVC applyTheme:self.theme];
        [self presentViewControllerWrappedInNavigationController:loginVC];
        [[LoginFunnel shared] logLoginStartInSettings];
    }
}

- (void)clearDonationHistory {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:WMFCommonStrings.confirmDeletionTitle
                                                                             message:WMFCommonStrings.confirmDeletionSubtitle
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:WMFCommonStrings.deleteActionTitle
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *_Nonnull action) {
                                                             [self deleteLocalHistory];
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 [self loadSections];
                                                                 [self.tableView reloadData];
                                                                 [self showDeletionConfirmation];
                                                             });
                                                         }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:WMFCommonStrings.cancelActionTitle
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

    [alertController addAction:deleteAction];
    [alertController addAction:cancelAction];
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteLocalHistory {
    [[WMFDonateDataControllerWrapper shared] deleteLocalDonationHistory];
}

- (void)showDeletionConfirmation {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:WMFCommonStrings.confirmedDeletion
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:WMFCommonStrings.okTitle style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Show temporary account
- (void)showTemporaryAccount {
    WMFTempAccountsSettingsViewController *tempAccountSettingsViewController = [[WMFTempAccountsSettingsViewController alloc] initWithDataStore:self.dataStore];
    [tempAccountSettingsViewController applyTheme:self.theme];
    [self.navigationController pushViewController:tempAccountSettingsViewController animated:YES];
}

#pragma mark - Clear Cache

- (void)showClearCacheActionSheet {
    NSString *message = WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-are-you-sure-message", nil, nil, @"Clearing cached data will free up about %1$@ of space. It will not delete your saved pages.", @"Message for the confirmation presented to the user to verify they are sure they want to clear clear cached data. %1$@ is replaced with the approximate file size in bytes that will be made available. Also explains that the action will not delete their saved pages.");
    NSString *bytesString = [NSByteCountFormatter stringFromByteCount:[NSURLCache sharedURLCache].currentDiskUsage countStyle:NSByteCountFormatterCountStyleFile];
    message = [NSString localizedStringWithFormat:message, bytesString];

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-are-you-sure-title", nil, nil, @"Clear cached data?", @"Title for the confirmation presented to the user to verify they are sure they want to clear clear cached data.") message:message preferredStyle:UIAlertControllerStyleAlert];
    typeof(self) __weak weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-ok", nil, nil, @"Clear cache", @"Confirm action to clear cached data")
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *_Nonnull action) {
                                                [weakSelf clearCache];
                                            }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"settings-clear-cache-cancel", nil, nil, @"Cancel", @"Cancel action to clear cached data {{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];

    [self presentViewController:sheet animated:YES completion:NULL];
}

- (void)clearCache {

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showClearCacheInProgressBanner) object:nil];
    [self performSelector:@selector(showClearCacheInProgressBanner) withObject:nil afterDelay:1.0];

    [self.dataStore clearTemporaryCache];

    WMFDatabaseHousekeeper *databaseHousekeeper = [WMFDatabaseHousekeeper new];
    WMFNavigationStateController *navigationStateController = [[WMFNavigationStateController alloc] initWithDataStore:self.dataStore];

    [self.dataStore performBackgroundCoreDataOperationOnATemporaryContext:^(NSManagedObjectContext *_Nonnull moc) {
        NSError *housekeepingError = nil;
        [databaseHousekeeper performHousekeepingOnManagedObjectContext:moc navigationStateController:navigationStateController cleanupLevel:WMFCleanupLevelHigh error:&housekeepingError];
        if (housekeepingError) {
            DDLogError(@"Error on cleanup: %@", housekeepingError);
            housekeepingError = nil;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showClearCacheInProgressBanner) object:nil];
            [[WMFAlertManager sharedInstance] showAlert:WMFLocalizedStringWithDefaultValue(@"clearing-cache-complete", nil, nil, @"Clearing cache complete.", @"Title of banner that appears after clearing cache completes. Clearing cache is a button triggered by the user in Settings.") sticky:NO dismissPreviousAlerts:YES tapCallBack:nil];
        });
    }];

    [SharedContainerCacheHousekeeping deleteStaleCachedItemsIn:SharedContainerCacheCommonNames.talkPageCache cleanupLevel:WMFCleanupLevelHigh];
    [SharedContainerCacheHousekeeping deleteStaleCachedItemsIn:SharedContainerCacheCommonNames.didYouKnowCache cleanupLevel:WMFCleanupLevelHigh];
}

- (void)showClearCacheInProgressBanner {
    [[WMFAlertManager sharedInstance] showAlert:WMFLocalizedStringWithDefaultValue(@"clearing-cache-in-progress", nil, nil, @"Clearing cache in progress.", @"Title of banner that appears when a user taps clear cache button in Settings. Informs the user that clearing of cache is in progress.") sticky:NO dismissPreviousAlerts:YES tapCallBack:nil];
}

- (void)logout {
    [self wmf_showKeepSavedArticlesOnDevicePanelIfNeededTriggeredBy:KeepSavedArticlesTriggerLogout
                                                              theme:self.theme
                                                         completion:^{
                                                             [self.dataStore.authenticationManager logoutInitiatedBy:LogoutInitiatorUser
                                                                                                          completion:^{
                                                                                                              [[LoginFunnel shared] logLogoutInSettings];
                                                                                                          }];
                                                         }];
}

#pragma mark - Languages

- (void)showLanguages {
    WMFPreferredLanguagesViewController *languagesVC = [WMFPreferredLanguagesViewController preferredLanguagesViewController];
    languagesVC.showExploreFeedCustomizationSettings = YES;
    languagesVC.delegate = self;
    [languagesVC applyTheme:self.theme];
    [self presentViewControllerWrappedInNavigationController:languagesVC];
}

- (void)languagesController:(WMFPreferredLanguagesViewController *)controller didUpdatePreferredLanguages:(NSArray<MWKLanguageLink *> *)languages {
    if ([languages count] > 1) {
        [[NSUserDefaults standardUserDefaults] wmf_setShowSearchLanguageBar:YES];
    } else {
        [[NSUserDefaults standardUserDefaults] wmf_setShowSearchLanguageBar:NO];
    }

    [self loadSections];
}

#pragma mark - Search

- (void)showSearch {
    WMFSearchSettingsViewController *searchSettingsViewController = [[WMFSearchSettingsViewController alloc] init];
    [searchSettingsViewController applyTheme:self.theme];
    [self.navigationController pushViewController:searchSettingsViewController animated:YES];
}

#pragma mark - Feed

- (void)showExploreFeedSettings {
    WMFExploreFeedSettingsViewController *feedSettingsVC = [[WMFExploreFeedSettingsViewController alloc] init];
    feedSettingsVC.dataStore = self.dataStore;
    [feedSettingsVC applyTheme:self.theme];
    [self.navigationController pushViewController:feedSettingsVC animated:YES];
}

#pragma mark - Notifications

- (void)showNotifications {
    WMFPushNotificationsSettingsViewController *pushSettingsVC = [[WMFPushNotificationsSettingsViewController alloc] initWithAuthenticationManager:self.authManager notificationsController:self.dataStore.notificationsController];
    [pushSettingsVC applyTheme:self.theme];
    [self.navigationController pushViewController:pushSettingsVC animated:YES];
}

#pragma mark - Year in Review

- (void)showYearInReview {
    [[WMFDonateFunnel shared] logYearInReviewSettingsDidTapItem];
    WMFYearInReviewSettingsViewController *yearInReviewSettingsVC = [[WMFYearInReviewSettingsViewController alloc] initWithDataStore:self.dataStore theme:self.theme];
    [self.navigationController pushViewController:yearInReviewSettingsVC animated:YES];
}

#pragma mark - Appearance

- (void)showAppearance {
    WMFAppearanceSettingsViewController *appearanceSettingsVC = [[WMFAppearanceSettingsViewController alloc] init];
    [appearanceSettingsVC applyTheme:self.theme];
    [self.navigationController pushViewController:appearanceSettingsVC animated:YES];
}

#pragma mark - Donate

- (void)showDonateForCell:(WMFSettingsTableViewCell *)settingsCell {
    // TODO: Delete cell
}

#pragma mark - Storage and syncing

- (void)showStorageAndSyncing {
    WMFStorageAndSyncingSettingsViewController *storageAndSyncingSettingsVC = [[WMFStorageAndSyncingSettingsViewController alloc] init];
    storageAndSyncingSettingsVC.dataStore = self.dataStore;
    [storageAndSyncingSettingsVC applyTheme:self.theme];
    [self.navigationController pushViewController:storageAndSyncingSettingsVC animated:YES];
}

- (void)showDatabasePopulation {
#if DEBUG
    [self tappedDatabasePopulation];
#endif
}

#pragma mark - Cell reloading

- (nullable NSIndexPath *)indexPathForVisibleCellOfType:(WMFSettingsMenuItemType)type {
    return [self.tableView.indexPathsForVisibleRows wmf_match:^BOOL(NSIndexPath *indexPath) {
        return ([self.tableView cellForRowAtIndexPath:indexPath].tag == type);
    }];
}

#pragma mark - Sections structure

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    NSArray *items = [self.sections[section] getItems];
    return items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    WMFTableHeaderFooterLabelView *header = (WMFTableHeaderFooterLabelView *)[self tableView:tableView viewForHeaderInSection:section];
    if (header) {
        return UITableViewAutomaticDimension;
    }

    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *text = self.sections.count > section ? [self.sections[section] getHeaderTitle] : nil;
    return [WMFTableHeaderFooterLabelView headerFooterViewForTableView:tableView text:text type:WMFTableHeaderFooterLabelViewType_Header setShortTextAsProse:NO theme:self.theme];
}

- (void)loadSections {
    self.sections = [[NSMutableArray alloc] init];

    [self.sections addObject:[self section_1]];
    [self.sections addObject:[self section_2]];
    [self.sections addObject:[self section_3]];
    [self.sections addObject:[self section_4]];
    [self.tableView reloadData];
}

#pragma mark - Section structure

- (WMFSettingsTableViewSection *)section_1 {
    NSMutableArray *items = [NSMutableArray array];
    BOOL primaryWikiHasTempAccounts = [[WMFTempAccountDataController shared] primaryWikiHasTempAccountsEnabled];
    if (_authManager.authStateIsTemporary && primaryWikiHasTempAccounts) {
        [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_TemporaryAccount]];
    }

    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_LoginAccount]];

    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:items
                                                                                  headerTitle:nil
                                                                                   footerText:nil];
    return section;
}

- (WMFSettingsTableViewSection *)section_2 {
    NSArray *commonItems = @[[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SearchLanguage],
                             [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Search]];
    NSMutableArray *items = [NSMutableArray arrayWithArray:commonItems];
    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ExploreFeed]];

    if ([[WMFYearInReviewDataController dataControllerForObjectiveC] shouldShowYearInReviewSettingsItemWithCountryCode:NSLocale.currentLocale.countryCode]) {
        [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_YearInReview]];
    }

    BOOL primaryWikiHasTempAccounts = [[WMFTempAccountDataController shared] primaryWikiHasTempAccountsEnabled];
    if (_authManager.authStateIsPermanent || (_authManager.authStateIsTemporary && primaryWikiHasTempAccounts)) {
        [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Notifications]];
    }

    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Appearance]];
    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_StorageAndSyncing]];
#if DEBUG
    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_DatabasePopulation]];
#endif
    [items addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_ClearCache]];
    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:items headerTitle:nil footerText:nil];
    return section;
}

- (WMFSettingsTableViewSection *)section_3 {
    NSMutableArray<WMFSettingsMenuItem *> *menuItems = [NSMutableArray array];
    WMFSettingsMenuItem *privacy = [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_PrivacyPolicy];
    WMFSettingsMenuItem *terms = [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_Terms];
    [menuItems addObject:privacy];
    [menuItems addObject:terms];

    BOOL hasDonations = [WMFDonateDataControllerWrapper shared].hasLocallySavedDonations;
    if (hasDonations) {
        [menuItems addObject:[WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_DonateHistory]];
    }

    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:menuItems
                                                                                  headerTitle:WMFLocalizedStringWithDefaultValue(@"main-menu-heading-legal", nil, nil, @"Privacy and Terms", @"Header text for the legal section of the menu. Consider using something informal, but feel free to use a more literal translation of \"Legal info\" if it seems more appropriate.")
                                                                                   footerText:WMFLocalizedStringWithDefaultValue(@"preference-summary-eventlogging-opt-in", nil, nil, @"Allow Wikimedia Foundation to collect information about how you use the app to make the app better", @"Description of preference that when checked enables data collection of user behavior.")];

    return section;
}

- (WMFSettingsTableViewSection *)section_4 {
    WMFSettingsTableViewSection *section = [[WMFSettingsTableViewSection alloc] initWithItems:@[
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_RateApp],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_SendFeedback],
        [WMFSettingsMenuItem itemForType:WMFSettingsMenuItemType_About]
    ]
                                                                                  headerTitle:nil
                                                                                   footerText:nil];
    return section;
}

#pragma mark - Scroll view

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self calculateNavigationBarHiddenStateFromObjCWithScrollView:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    if (self.viewIfLoaded == nil) {
        return;
    }
    self.theme = theme;
    self.tableView.backgroundColor = theme.colors.baseBackground;
    self.tableView.indicatorStyle = theme.scrollIndicatorStyle;
    self.view.backgroundColor = theme.colors.baseBackground;
    [self loadSections];

    [self updateProfileButtonFromObjC];
    [self themeNavigationBarLeadingTitleViewFromObjC];
    [self themeTopSafeAreaOverlayFromObjCWithScrollView:self.tableView];
}

#pragma Mark WMFAccountViewControllerDelegate

- (void)accountViewControllerDidTapLogout:(WMFAccountViewController *_Nonnull)accountViewController {
    [self logout];
    [self loadSections];
}

#pragma mark - Notifications Center

- (void)pushNotificationBannerDidDisplayInForeground:(NSNotification *)notification {
    [self.dataStore.remoteNotificationsController triggerLoadNotificationsWithForce:YES];
}

- (void)userWasLoggedIn:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadSections];
    });
}

- (void)userWasLoggedOut:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadSections];
    });
}
@end

NS_ASSUME_NONNULL_END
