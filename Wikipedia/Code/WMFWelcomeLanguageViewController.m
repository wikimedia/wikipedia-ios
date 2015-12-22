
#import "WMFWelcomeLanguageViewController.h"
#import "WMFWelcomeLanguageTableViewCell.h"
#import "MWKLanguageLinkController.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKLanguageLink.h"
#import "LanguagesViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"


@interface WMFWelcomeLanguageViewController ()<LanguageSelectionDelegate>

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UITableView* languageTableView;
@property (strong, nonatomic) IBOutlet UIButton* moreLanguagesButton;
@property (strong, nonatomic) IBOutlet UIButton* nextStepButton;
@property (strong, nonatomic) IBOutlet UILabel* footnoteLabel;
@property (strong, nonatomic) IBOutlet UIButton* howThisWorksButton;

@end

@implementation WMFWelcomeLanguageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.languageTableView.editing = YES;

    self.titleLabel.text = MWLocalizedString(@"welcome-languages-title", nil);
    [self.moreLanguagesButton setTitle:MWLocalizedString(@"welcome-languages-more-languages-button-title", nil) forState:UIControlStateNormal];
    [self.nextStepButton setTitle:MWLocalizedString(@"welcome-languages-button-title", nil) forState:UIControlStateNormal];
    self.footnoteLabel.text = MWLocalizedString(@"welcome-languages-footnote-text", nil);
    [self.howThisWorksButton setTitle:MWLocalizedString(@"welcome-languages-more-info-button-text", nil) forState:UIControlStateNormal];
}

- (IBAction)showHowThisWorksAlert:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:MWLocalizedString(@"welcome-languages-more-info-button-text", nil) message:MWLocalizedString(@"welcome-languages-more-info-text", nil) delegate:nil cancelButtonTitle:MWLocalizedString(@"welcome-languages-more-info-done-button", nil) otherButtonTitles:nil];
    [alert show];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self lockTableViewIfContentFits];
}

- (void)lockTableViewIfContentFits {
    //Don't make it scroll unless we have too (rare to have so many languages)
    if (self.languageTableView.contentSize.height < self.languageTableView.frame.size.height) {
        self.languageTableView.scrollEnabled = NO;
    } else {
        self.languageTableView.scrollEnabled = YES;
    }
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [[MWKLanguageLinkController sharedInstance].preferredLanguages count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    WMFWelcomeLanguageTableViewCell* cell = (id)[tableView dequeueReusableCellWithIdentifier:[WMFWelcomeLanguageTableViewCell wmf_nibName]
                                                                                forIndexPath:indexPath];
    MWKLanguageLink* langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[indexPath.row];
    cell.numberLabel.text       = [NSString stringWithFormat:@"%li", indexPath.row + 1];
    cell.languageNameLabel.text = langLink.name;

    //can only delete non-OS languages
    if (![[MWKLanguageLinkController sharedInstance] languageIsOSLanguage:langLink]) {
        cell.deleteButtonTapped = ^{
            MWKLanguageLink* langLink = [MWKLanguageLinkController sharedInstance].preferredLanguages[indexPath.row];
            [[MWKLanguageLinkController sharedInstance] removePreferredLanguage:langLink];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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
