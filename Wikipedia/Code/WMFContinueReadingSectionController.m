#import "WMFContinueReadingSectionController.h"
#import "WMFArticleListCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "NSString+WMFExtras.h"
#import "MWKSection.h"
#import "MWKSectionList.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "NSDate+WMFRelativeDate.h"
@import WMFKit;

static NSString *const WMFContinueReadingSectionIdentifier = @"WMFContinueReadingSectionIdentifier";

@interface WMFContinueReadingSectionController ()

@property (nonatomic, strong, readwrite) NSURL *articleURL;

@end

@implementation WMFContinueReadingSectionController

- (instancetype)initWithArticleURL:(NSURL *)articleURL
                         dataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(articleURL.wmf_title);
    self = [super initWithDataStore:dataStore items:@[articleURL]];
    if (self) {
        self.articleURL = articleURL;
    }
    return self;
}

- (MWKArticle *)article {
    return [self.dataStore existingArticleWithURL:self.articleURL];
}

#pragma mark - WMFBaseExploreSectionController

- (id)sectionIdentifier {
    return WMFContinueReadingSectionIdentifier;
}

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"home-continue-reading-mini"];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-continue-reading-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    NSDate *resignActiveDate = [[NSUserDefaults wmf_userDefaults] wmf_appResignActiveDate];
    NSString *relativeTimeString = [resignActiveDate wmf_relativeTimestamp];
    return [[NSAttributedString alloc] initWithString:[relativeTimeString wmf_stringByCapitalizingFirstCharacter] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString *)cellIdentifier {
    return [WMFArticleListCollectionViewCell wmf_nibName];
}

- (UINib *)cellNib {
    return [WMFArticleListCollectionViewCell wmf_classNib];
}

- (NSUInteger)numberOfPlaceholderCells {
    return 0;
}

- (void)configureCell:(WMFArticleListCollectionViewCell *)cell withItem:(NSURL *)item atIndexPath:(NSIndexPath *)indexPath {
    MWKArticle *article = [self article];
    cell.titleText = item.wmf_title;
    cell.descriptionText = [[article entityDescription] wmf_stringByCapitalizingFirstCharacter];
    [cell setImage:article.image];
}

- (CGFloat)estimatedRowHeight {
    return [WMFArticleListCollectionViewCell estimatedRowHeight];
}

- (NSString *)analyticsContentType {
    return @"Continue Reading";
}

- (UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = [self urlForItemAtIndexPath:indexPath];
    WMFArticleViewController *vc = [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
    return vc;
}

- (BOOL)prefersWiderColumn {
    return YES;
}

#pragma mark - WMFTitleProviding

- (nullable NSURL *)urlForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.articleURL;
}

#pragma mark - Utility

- (NSString *)summaryForArticle {
    MWKArticle *cachedArticle = [self.dataStore existingArticleWithURL:self.articleURL];
    if (cachedArticle.entityDescription.length) {
        return [cachedArticle.entityDescription wmf_stringByCapitalizingFirstCharacter];
    } else {
        return [[cachedArticle.sections firstNonEmptySection] summary];
    }
}

@end
