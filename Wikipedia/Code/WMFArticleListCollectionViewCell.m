#import "WMFArticleListCollectionViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"
#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
#import "UITableViewCell+SelectedBackground.h"
#import "UIImageView+WMFPlaceholder.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"
#import "Wikipedia-Swift.h"

@interface WMFArticleListCollectionViewCell ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView *articleImageView;

@end

@implementation WMFArticleListCollectionViewCell

+ (CGFloat)estimatedRowHeight {
    return 60.f;
}

- (void)configureImageViewWithPlaceholder {
    self.articleImageView.wmf_placeholderView.alpha = 1;
}

- (void)configureCell {
    [self configureContentView];

    [self wmf_addSelectedBackgroundView];
    [self configureImageViewWithPlaceholder];
}

- (void)configureContentView {
    self.clipsToBounds = NO;
    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text = nil;
    self.descriptionLabel.text = nil;
    [self configureImageViewWithPlaceholder];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // apply customizations for base class only
    if ([self isMemberOfClass:[WMFArticleListCollectionViewCell class]]) {
        // need to aspect-fit placeholder since our image view is too small
        self.articleImageView.wmf_placeholderView.contentMode = UIViewContentModeScaleAspectFit;
        // use white background, gray default looks bad w/ this cell
        self.articleImageView.wmf_placeholderView.backgroundColor = [UIColor whiteColor];
    }
    [self configureImageViewWithPlaceholder];
    [self wmf_makeCellDividerBeEdgeToEdge];
    self.titleLabel.textAlignment = NSTextAlignmentNatural;
    self.descriptionLabel.textAlignment = NSTextAlignmentNatural;
    [self wmf_configureSubviewsForDynamicType];
}

#pragma mark - Title

- (void)setTitleText:(NSString *)titleText {
    self.titleLabel.text = titleText;
}

- (NSString *)titleText {
    return self.titleLabel.text;
}

#pragma mark - Description

- (void)setDescriptionText:(NSString *)descriptionText {
    self.descriptionLabel.text = descriptionText;
}

- (NSString *)descriptionText {
    return self.descriptionLabel.text;
}

#pragma mark - Image

- (void)setImageURL:(NSURL *)imageURL failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    [self.articleImageView wmf_setImageWithURL:imageURL detectFaces:YES failure:failure success:success];
}

- (void)setImage:(MWKImage *)image failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    [self.articleImageView wmf_setImageWithMetadata:image detectFaces:YES failure:failure success:success];
}

- (void)setImageURL:(NSURL *)imageURL {
    [self setImageURL:imageURL failure:WMFIgnoreErrorHandler success:WMFIgnoreSuccessHandler];
}

- (void)setImage:(MWKImage *)image {
    [self setImage:image failure:WMFIgnoreErrorHandler success:WMFIgnoreSuccessHandler];
}

@end
