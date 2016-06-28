
#import "WMFContinueReadingSectionController.h"
#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "NSString+WMFExtras.h"
#import "UITableViewCell+WMFLayout.h"
#import "MWKSection.h"
#import "MWKSectionList.h"
#import "WMFArticleBrowserViewController.h"
#import "Wikipedia-Swift.h"
#import "NSDate+WMFRelativeDate.h"

static NSString* const WMFContinueReadingSectionIdentifier = @"WMFContinueReadingSectionIdentifier";

@interface WMFContinueReadingSectionController ()

@property (nonatomic, strong, readwrite) NSURL* articleURL;

@end

@implementation WMFContinueReadingSectionController

- (instancetype)initWithArticleURL:(NSURL*)articleURL
                         dataStore:(MWKDataStore*)dataStore
{
    NSParameterAssert(articleURL.wmf_title);
    self = [super initWithDataStore:dataStore items:@[articleURL]];
    if (self) {
        self.articleURL = articleURL;
    }
    return self;
}

- (MWKArticle*)article {
    return [self.dataStore existingArticleWithURL:self.articleURL];
}

#pragma mark - WMFBaseExploreSectionController

- (id)sectionIdentifier {
    return WMFContinueReadingSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"home-continue-reading-mini"];
}

- (UIColor*)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor*)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString*)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-continue-reading-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString*)headerSubTitle {
    NSDate* resignActiveDate     = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    NSString* relativeTimeString = [resignActiveDate wmf_relativeTimestamp];
    return [[NSAttributedString alloc] initWithString:[relativeTimeString wmf_stringByCapitalizingFirstCharacter] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString*)cellIdentifier {
    return [WMFArticleListTableViewCell wmf_nibName];
}

- (UINib*)cellNib {
    return [WMFArticleListTableViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 0;
}

- (void)configureCell:(WMFArticleListTableViewCell*)cell withItem:(NSURL*)item atIndexPath:(NSIndexPath*)indexPath {
    MWKArticle* article = [self article];
    cell.titleText       = item.wmf_title;
    cell.descriptionText = [[article entityDescription] wmf_stringByCapitalizingFirstCharacter];
    [cell setImage:article.image];
    [cell wmf_layoutIfNeededIfOperatingSystemVersionLessThan9_0_0];
}

- (CGFloat)estimatedRowHeight {
    return [WMFArticleListTableViewCell estimatedRowHeight];
}

- (NSString*)analyticsContentType {
    return @"Continue Reading";
}

- (UIViewController*)detailViewControllerForItemAtIndexPath:(NSIndexPath*)indexPath {
    NSURL* url              = [self urlForItemAtIndexPath:indexPath];
    WMFArticleViewController* vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
    return vc;
}

#pragma mark - WMFTitleProviding

- (nullable NSURL*)urlForItemAtIndexPath:(NSIndexPath*)indexPath {
    return self.articleURL;
}

#pragma mark - Utility

- (NSString*)summaryForTitle:(MWKTitle*)title {
    MWKArticle* cachedArticle = [self.dataStore existingArticleWithURL:self.articleURL];
    if (cachedArticle.entityDescription.length) {
        return [cachedArticle.entityDescription wmf_stringByCapitalizingFirstCharacter];
    } else {
        return [[cachedArticle.sections firstNonEmptySection] summary];
    }
}

@end
