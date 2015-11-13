
#import "WMFArticleListTableViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"
#import "UIImageView+WMFImageFetching.h"

@interface WMFArticleListTableViewCell ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView* articleImageView;

@end


@implementation WMFArticleListTableViewCell

- (void)configureImageViewWithPlaceholder {
    [self.articleImageView wmf_reset];
    self.articleImageView.tintColor       = [UIColor wmf_placeholderImageTintColor];
    self.articleImageView.image           = [UIImage wmf_placeholderImage];
    if (self.articleImageView.frame.size.width > self.articleImageView.image.size.width) {
        self.articleImageView.backgroundColor = [UIColor wmf_placeholderImageBackgroundColor];
        self.articleImageView.contentMode = UIViewContentModeCenter;
    } else {
        self.articleImageView.backgroundColor = [UIColor clearColor];
        self.articleImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
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
    self.titleLabel.text       = nil;
    self.descriptionLabel.text = nil;
    [self.articleImageView wmf_reset];
    [self configureImageViewWithPlaceholder];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureImageViewWithPlaceholder];
}

#pragma mark - Title

- (void)setTitleText:(NSString*)titleText {
    self.titleLabel.text = titleText;
}

- (NSString*)titleText {
    return self.titleLabel.text;
}

#pragma mark - Description

- (void)setDescriptionText:(NSString*)descriptionText {
    self.descriptionLabel.text = descriptionText;
}

- (NSString*)descriptionText {
    return self.descriptionLabel.text;
}

#pragma mark - Image

- (void)setImageURL:(NSURL*)imageURL {
    [self.articleImageView wmf_setImageWithURL:imageURL detectFaces:YES];
}

- (void)setImage:(MWKImage*)image {
    [self.articleImageView wmf_setImageWithMetadata:image detectFaces:YES];
}

@end
