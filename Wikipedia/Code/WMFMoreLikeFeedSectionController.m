
#import "WMFMoreLikeFeedSectionController.h"
#import "WMFArticlePreviewCollectionViewCell.h"
#import "WMFArticlePreview.h"

@implementation WMFMoreLikeFeedSectionController

- (UIImage *)headerIcon {
    return [UIImage imageNamed:@"recent-mini"];
}

- (UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (NSAttributedString *)headerTitle {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"explore-continue-related-heading", nil) attributes:@{NSForegroundColorAttributeName: [UIColor wmf_exploreSectionHeaderTitleColor]}];
}

- (NSAttributedString *)headerSubTitle {
    return [[NSAttributedString alloc] initWithString:self.url.wmf_title attributes:@{NSForegroundColorAttributeName: [UIColor wmf_blueTintColor]}];
}

- (NSString *)cellIdentifier {
    return [WMFArticlePreviewCollectionViewCell identifier];
}

- (BOOL)prefersWiderColumn {
    return YES /*FBTweakValue(@"Explore", @"General", @"Put 'Because You Read' in Wider Column", YES)*/;
}



@end
