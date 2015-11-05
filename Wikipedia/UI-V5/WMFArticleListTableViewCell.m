
#import "WMFArticleListTableViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"
#import "UIImageView+WMFImageFetching.h"

@implementation WMFArticleListTableViewCell

- (void)configureImageViewWithPlaceholder {
//    self.articleImageView.contentMode     = UIViewContentModeCenter;
//    self.articleImageView.backgroundColor = [UIColor wmf_placeholderImageBackgroundColor];
    self.articleImageView.tintColor = [UIColor wmf_placeholderImageTintColor];
    self.articleImageView.image     = [UIImage wmf_placeholderImage];
}

- (void)configureCell {
    [self configureContentView];
    [self configureImageViewWithPlaceholder];
}

- (void)configureContentView {
    self.clipsToBounds               = NO;
    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text = nil;
    [self.articleImageView wmf_reset];
    [self configureImageViewWithPlaceholder];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureImageViewWithPlaceholder];
}

@end
