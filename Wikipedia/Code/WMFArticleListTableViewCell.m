#import "WMFArticleListTableViewCell.h"
#import "UITableViewCell+SelectedBackground.h"
#import <WMF/UITableViewCell+WMFEdgeToEdgeSeparator.h>
#import <WMF/UIImageView+WMFImageFetching.h>
#import "Wikipedia-Swift.h"

@interface WMFArticleListTableViewCell ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView *articleImageView;

@end

@implementation WMFArticleListTableViewCell

+ (CGFloat)estimatedRowHeight {
    return 60.f;
}

- (void)configureCell {
    [self configureContentView];
    [self wmf_addSelectedBackgroundView];
}

- (void)configureContentView {
    self.clipsToBounds = NO;
    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text = nil;
    self.descriptionLabel.text = nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self wmf_makeCellDividerBeEdgeToEdge];
    self.titleLabel.textAlignment = NSTextAlignmentNatural;
    self.descriptionLabel.textAlignment = NSTextAlignmentNatural;
    // apply customizations for base class only
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
    [self.articleImageView wmf_setImageWithURL:imageURL detectFaces:YES onGPU:YES failure:failure success:success];
}

- (void)setImage:(MWKImage *)image failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success {
    [self.articleImageView wmf_setImageWithMetadata:image detectFaces:YES onGPU:YES failure:failure success:success];
}

- (void)setImageURL:(NSURL *)imageURL {
    [self setImageURL:imageURL failure:WMFIgnoreErrorHandler success:WMFIgnoreSuccessHandler];
}

- (void)setImage:(MWKImage *)image {
    [self setImage:image failure:WMFIgnoreErrorHandler success:WMFIgnoreSuccessHandler];
}

@end
