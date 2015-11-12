
#import "WMFArticlePreviewTableViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"
#import "UIButton+WMFButton.h"
#import "UIImageView+WMFImageFetching.h"
#import "WMFSaveButtonController.h"
#import "MWKImage.h"

@interface WMFArticlePreviewTableViewCell ()

@property (strong, nonatomic) WMFSaveButtonController* saveButtonController;

/**
 *  Label used to display the receiver's @c title.
 *
 */
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;

/**
 *  Label used to display the receiver's @c description.
 *
 */
@property (nonatomic, strong) IBOutlet UILabel* descriptionLabel;

/**
 *  Label used to display the receiver's @c snippet.
 *
 */
@property (nonatomic, strong) IBOutlet UILabel* snippetLabel;

/**
 *  The view used to display the receiver's @c image.
 */
@property (strong, nonatomic) IBOutlet UIImageView* articleImageView;

/**
 *  The button used to display the saved state of the receiver's @c title.
 *
 *  This class will automatically
 *  configure any buttons connected to this property in Interface Builder (during @c awakeFromNib).
 */
@property (strong, nonatomic) IBOutlet UIButton* saveButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintTrailing;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintAboveDescription;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintBelowDescription;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* imageHeightConstraint;

@property (nonatomic) CGFloat paddingAboveDescriptionFromIB;
@property (nonatomic) CGFloat paddingBelowDescriptionFromIB;

@end

@implementation WMFArticlePreviewTableViewCell

#pragma mark - Setup

- (void)configureImageViewWithPlaceholder {
    [self.articleImageView wmf_reset];
    self.articleImageView.contentMode     = UIViewContentModeCenter;
    self.articleImageView.backgroundColor = [UIColor wmf_placeholderImageBackgroundColor];
    self.articleImageView.tintColor       = [UIColor wmf_placeholderImageTintColor];
    self.articleImageView.image           = [UIImage wmf_placeholderImage];
}

- (void)configureCell {
    [self configureContentView];
    [self configureImageViewWithPlaceholder];
    [self.saveButton wmf_setButtonType:WMFButtonTypeBookmarkMini];
    self.saveButton.tintColor = [UIColor wmf_blueTintColor];
    [self.saveButton setTitleColor:[UIColor wmf_blueTintColor] forState:UIControlStateNormal];
}

- (void)configureContentView {
    self.clipsToBounds               = NO;
    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text             = nil;
    self.descriptionLabel.text       = nil;
    self.snippetLabel.attributedText = nil;
    [self.articleImageView wmf_reset];
    [self configureImageViewWithPlaceholder];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self rememberSettingsFromIB];
    [self configureImageViewWithPlaceholder];
}

- (void)rememberSettingsFromIB {
    self.paddingAboveDescriptionFromIB = self.paddingConstraintAboveDescription.constant;
    self.paddingBelowDescriptionFromIB = self.paddingConstraintBelowDescription.constant;
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
    if (self.descriptionLabel.text.length == 0) {
        [self removeDescriptionVerticalPadding];
    } else {
        [self restoreDescriptionVerticalPadding];
    }
}

- (NSString*)descriptionText {
    return self.descriptionLabel.text;
}

- (void)removeDescriptionVerticalPadding {
    self.paddingConstraintAboveDescription.constant = 0;
    self.paddingConstraintBelowDescription.constant = 0;
}

- (void)restoreDescriptionVerticalPadding {
    self.paddingConstraintAboveDescription.constant = self.paddingAboveDescriptionFromIB;
    self.paddingConstraintBelowDescription.constant = self.paddingBelowDescriptionFromIB;
}

#pragma mark - Snippet

- (void)setSnippetText:(NSString*)snippetText {
    if (!snippetText.length) {
        self.snippetLabel.attributedText = nil;
        return;
    }
    self.snippetLabel.attributedText = [[NSAttributedString alloc] initWithString:snippetText attributes:[[self class] snippetAttributes]];
}

- (NSString*)snippetText {
    return self.snippetLabel.attributedText.string;
}

+ (NSDictionary*)snippetAttributes {
    static NSDictionary* attributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
        pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        pStyle.baseWritingDirection = NSWritingDirectionNatural;
        pStyle.lineHeightMultiple = 1.35;
        attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                       NSForegroundColorAttributeName: [UIColor blackColor],
                       NSParagraphStyleAttributeName: pStyle};
    });
    return attributes;
}

#pragma mark - Image

- (void)setImageURL:(NSURL*)imageURL {
    [self.articleImageView wmf_setImageWithURL:imageURL detectFaces:YES];
    if (imageURL) {
        [self restoreImageToFullHeight];
    } else {
        [self collapseImageHeightToZero];
    }
}

- (void)setImage:(MWKImage*)image {
    [self.articleImageView wmf_setImageWithMetadata:image detectFaces:YES];
    if (image) {
        [self restoreImageToFullHeight];
    } else {
        [self collapseImageHeightToZero];
    }
}

- (void)collapseImageHeightToZero {
    self.imageHeightConstraint.constant = 0;
}

- (void)restoreImageToFullHeight {
    self.imageHeightConstraint.constant = [self sixteenByNineHeightForImageWithSameHeightForLandscape];
}

- (CGFloat)sixteenByNineHeightForImageWithSameHeightForLandscape {
    // Design said landscape should use same height used for portrait.
    CGFloat horizontalPadding = self.paddingConstraintLeading.constant + self.paddingConstraintTrailing.constant;
    CGFloat ratio             = (9.0 / 16.0);
    return floor((MIN(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds)) - horizontalPadding) * ratio);
}

#pragma mark - Saving

- (WMFSaveButtonController*)saveButtonController {
    if (!_saveButtonController) {
        self.saveButtonController = [[WMFSaveButtonController alloc] init];
    }
    return _saveButtonController;
}

- (void)setTitle:(MWKTitle*)title {
    self.saveButtonController.title = title;
}

- (MWKTitle*)title {
    return self.saveButtonController.title;
}

- (void)setSavedPageList:(MWKSavedPageList*)savedPageList {
    self.saveButtonController.savedPageList = savedPageList;
}

- (MWKSavedPageList*)savedPageList {
    return self.saveButtonController.savedPageList;
}

@end
