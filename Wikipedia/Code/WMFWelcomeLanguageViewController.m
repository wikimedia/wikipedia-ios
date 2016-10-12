#import "WMFWelcomeLanguageViewController_Testing.h"
#import "Wikipedia-Swift.h"
#import "WMFWelcomeLanguageTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKLanguageLink.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIButton+WMFWelcomeNextButton.h"
#import "WMFLanguagesViewController.h"

@interface WMFWelcomeLanguageViewController () <WMFLanguagesViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *languageTableView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (strong, nonatomic) IBOutlet UIButton *moreLanguagesButton;
@property (strong, nonatomic) IBOutlet UIButton *nextStepButton;
@property (strong, nonatomic) IBOutlet WelcomeLanguagesAnimationView *animationView;

@end

@implementation WMFWelcomeLanguageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.languageTableView.editing = YES;
    self.languageTableView.alwaysBounceVertical = NO;

    self.titleLabel.text =
        [MWLocalizedString(@"welcome-languages-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];

    self.subTitleLabel.text = MWLocalizedString(@"welcome-languages-sub-title", nil);

    [self.moreLanguagesButton setTitle:MWLocalizedString(@"welcome-languages-add-button", nil)
                              forState:UIControlStateNormal];

    [self.nextStepButton wmf_configureAsWelcomeNextButton];

    self.animationView.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    //HAX: to maintain fairly consistent margins above and below the welcome panels
    // their content is constrained to vertically center the image and labels as a
    // whole. This is trickier to do with a table which has a variable number of cells.
    // This hack vertically centers this panel's table contents. Note the image and
    // labels are part of the table so the table's scroll view can be used to scroll
    // the image, labels, and table cells as a group if needed (such as when many
    // language cells are added) - this is expecially important on small screens such
    // as a 4s.
    [self addTopInsetToVerticallyCenterLanguagesTableContentIfNeeded];
}

- (void)addTopInsetToVerticallyCenterLanguagesTableContentIfNeeded {
    CGFloat topInsetRequiredToCenterTableContent =
        (self.languageTableView.frame.size.height - self.languageTableView.contentSize.height) / 2.f;
    if (topInsetRequiredToCenterTableContent > 0) {
        self.languageTableView.contentInset = UIEdgeInsetsMake(topInsetRequiredToCenterTableContent, 0, 0, 0);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    BOOL shouldAnimate = !self.hasAlreadyFaded;
    [super viewDidAppear:animated];
    if (shouldAnimate) {
        [self.animationView beginAnimations];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([[MWKLanguageLinkController sharedInstance].preferredLanguages count] > 1) {
        [[NSUserDefaults wmf_userDefaults] wmf_setShowSearchLanguageBar:YES];
    } else {
        [[NSUserDefaults wmf_userDefaults] wmf_setShowSearchLanguageBar:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateDeleteButtonsVisibility];
}

- (void)updateDeleteButtonsVisibility {
    for (WMFWelcomeLanguageTableViewCell *cell in self.languageTableView.visibleCells) {
        cell.deleteButton.hidden = ([MWKLanguageLinkController sharedInstance].preferredLanguages.count == 1) ? YES : NO;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[MWKLanguageLinkController sharedInstance].preferredLanguages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFWelcomeLanguageTableViewCell *cell = (id)[tableView dequeueReusableCellWithIdentifier:[WMFWelcomeLanguageTableViewCell wmf_nibName]
                                                                                forIndexPath:indexPath];
    MWKLanguageLink *langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[indexPath.row];
    cell.languageName = langLink.name;

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[MWKLanguageLinkController sharedInstance].preferredLanguages count] > 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        MWKLanguageLink *langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[indexPath.row];
        [[MWKLanguageLinkController sharedInstance] removePreferredLanguage:langLink];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self updateDeleteButtonsVisibility];

        [self useFirstPreferredLanguageAsSearchLanguage];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[MWKLanguageLinkController sharedInstance].preferredLanguages count] > 1) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    MWKLanguageLink *langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[sourceIndexPath.row];
    [[MWKLanguageLinkController sharedInstance] reorderPreferredLanguage:langLink toIndex:destinationIndexPath.row];
    [self.languageTableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    [self useFirstPreferredLanguageAsSearchLanguage];
}

- (void)useFirstPreferredLanguageAsSearchLanguage {
    MWKLanguageLink *firstPreferredLanguage = [[MWKLanguageLinkController sharedInstance] appLanguage];

    [[NSUserDefaults wmf_userDefaults] wmf_setCurrentSearchLanguageDomain:firstPreferredLanguage.siteURL];
}

- (IBAction)addLanguages:(id)sender {
    WMFLanguagesViewController *languagesVC = [WMFLanguagesViewController nonPreferredLanguagesViewController];
    languagesVC.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:NULL];
}

#pragma mark - LanguageSelectionDelegate

- (void)languagesController:(WMFLanguagesViewController *)controller didSelectLanguage:(MWKLanguageLink *)language {
    [[MWKLanguageLinkController sharedInstance] appendPreferredLanguage:language];
    [self.languageTableView reloadData];
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

@end
