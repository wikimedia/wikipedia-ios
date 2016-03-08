
#import "WMFWelcomeLanguageViewController_Testing.h"
#import "Wikipedia-Swift.h"
#import "WMFWelcomeLanguageTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKLanguageLink.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIViewController+WMFWelcomeNavigation.h"
#import "UIButton+WMFWelcomeNextButton.h"

@interface WMFWelcomeLanguageViewController ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* subTitleLabel;
@property (strong, nonatomic) IBOutlet UIButton* moreLanguagesButton;
@property (strong, nonatomic) IBOutlet UIButton* nextStepButton;
@property (strong, nonatomic) IBOutlet UIView* dividerAboveNextStepButton;
@property (strong, nonatomic) IBOutlet WelcomeLanguagesAnimationView* animationView;

@end

@implementation WMFWelcomeLanguageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.languageTableView.editing = YES;

    self.titleLabel.text =
        [MWLocalizedString(@"welcome-languages-title", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];

    self.subTitleLabel.text = MWLocalizedString(@"welcome-languages-sub-title", nil);

    [self.moreLanguagesButton setTitle:MWLocalizedString(@"welcome-languages-add-button", nil)
                              forState:UIControlStateNormal];

    [self.nextStepButton wmf_configureAsWelcomeNextButton];

    self.dividerAboveNextStepButton.backgroundColor = [UIColor wmf_welcomeNextButtonDividerBackgroundColor];

    [self wmf_setupTransparentWelcomeNavigationBarWithBackChevron];
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
        [[NSUserDefaults standardUserDefaults] wmf_setShowSearchLanguageBar:YES];
    } else {
        [[NSUserDefaults standardUserDefaults] wmf_setShowSearchLanguageBar:NO];
    }
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [[MWKLanguageLinkController sharedInstance].preferredLanguages count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    WMFWelcomeLanguageTableViewCell* cell = (id)[tableView dequeueReusableCellWithIdentifier:[WMFWelcomeLanguageTableViewCell wmf_nibName]
                                                                                forIndexPath:indexPath];
    MWKLanguageLink* langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[indexPath.row];
    cell.numberLabel.text       = [NSString stringWithFormat:@"%ld", (long)indexPath.row + 1];
    cell.languageNameLabel.text = langLink.localizedName;

    //can only delete non-OS languages
    if (![[MWKLanguageLinkController sharedInstance] languageIsOSLanguage:langLink]) {
        cell.deleteButtonTapped = ^{
            MWKLanguageLink* langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[indexPath.row];
            [[MWKLanguageLinkController sharedInstance] removePreferredLanguage:langLink];
            [tableView reloadData];
        };
    }
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
    return UITableViewCellEditingStyleNone; //remove delete control
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    MWKLanguageLink* langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[sourceIndexPath.row];
    [[MWKLanguageLinkController sharedInstance] reorderPreferredLanguage:langLink toIndex:destinationIndexPath.row];
    [self.languageTableView reloadData];
}

- (IBAction)addLanguages:(id)sender {
    LanguagesViewController* languagesVC = [LanguagesViewController wmf_initialViewControllerFromClassStoryboard];
    languagesVC.showPreferredLanguges     = NO;
    languagesVC.languageSelectionDelegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:languagesVC] animated:YES completion:NULL];
}

#pragma mark - LanguageSelectionDelegate

- (void)languagesController:(LanguagesViewController*)controller didSelectLanguage:(MWKLanguageLink*)language {
    [[MWKLanguageLinkController sharedInstance] appendPreferredLanguage:language];
    [self.languageTableView reloadData];
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

@end
