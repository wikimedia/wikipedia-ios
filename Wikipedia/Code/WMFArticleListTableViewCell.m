
#import "WMFArticleListTableViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"
#import "UIImageView+WMFImageFetching.h"
#import "UITableViewCell+SelectedBackground.h"
#import "UIImageView+WMFPlaceholder.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

@interface WMFArticleListTableViewCell ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView* articleImageView;

@end


@implementation WMFArticleListTableViewCell

- (void)configureImageViewWithPlaceholder {
    [self.articleImageView wmf_configureWithDefaultPlaceholder];

    // apply customizations for base class only
    if ([self isMemberOfClass:[WMFArticleListTableViewCell class]]) {
        // need to aspect-fit placeholder since our image view is too small
        self.articleImageView.contentMode = UIViewContentModeScaleAspectFit;
        // use clear background, gray default looks bad w/ this cell
        self.articleImageView.backgroundColor = [UIColor clearColor];
    }
}

- (void)configureCell {
    [self configureContentView];
    [self wmf_addSelectedBackgroundView];
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
    [self configureImageViewWithPlaceholder];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureImageViewWithPlaceholder];
    [self wmf_makeCellDividerBeEdgeToEdge];
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
