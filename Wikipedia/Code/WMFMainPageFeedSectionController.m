
#import "WMFMainPageFeedSectionController.h"
#import "WMFArticleListCollectionViewCell.h"
#import "WMFArticlePreview.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFMainPageFeedSectionController

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"news-mini"];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-main-page-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:[[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:[NSDate date]] attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderSubTitleColor]}];
}

- (NSString *)cellIdentifier {
    return [WMFArticleListCollectionViewCell identifier];
}


@end

NS_ASSUME_NONNULL_END
