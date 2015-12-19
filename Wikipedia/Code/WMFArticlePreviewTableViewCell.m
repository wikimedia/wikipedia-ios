
#import "WMFArticlePreviewTableViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIButton+WMFButton.h"
#import "WMFSaveButtonController.h"
#import "MWKImage.h"
#import "UITableViewCell+SelectedBackground.h"
#import <Masonry/Masonry.h>
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

@interface WMFArticlePreviewTableViewCell ()

@property (strong, nonatomic) IBOutlet UILabel* snippetLabel;
@property (strong, nonatomic) IBOutlet UIButton* saveButton;

@property (strong, nonatomic) WMFSaveButtonController* saveButtonController;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintTrailing;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintAboveDescription;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* paddingConstraintBelowDescription;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint* imageHeightConstraint;

@property (strong, nonatomic) UIVisualEffectView* blurView;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicator;

@property (nonatomic) CGFloat paddingAboveDescriptionFromIB;
@property (nonatomic) CGFloat paddingBelowDescriptionFromIB;

@end

@implementation WMFArticlePreviewTableViewCell

#pragma mark - Setup

- (void)setLoading:(BOOL)loading {
    self.blurView.hidden = !loading;
    if (loading) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.snippetLabel.attributedText        = nil;
    self.saveButtonController.title         = nil;
    self.saveButtonController.savedPageList = nil;
    self.loading                            = NO;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self rememberSettingsFromIB];
    [self.saveButton wmf_setButtonType:WMFButtonTypeBookmarkMini];
    self.saveButton.tintColor = [UIColor wmf_blueTintColor];
    [self.saveButton setTitleColor:[UIColor wmf_blueTintColor] forState:UIControlStateNormal];
    self.saveButtonController.button = self.saveButton;
    [self wmf_makeCellDividerBeEdgeToEdge];
    [self setupBlurViewAndLoadingIndicator];
    self.loading = NO;
}

- (void)setupBlurViewAndLoadingIndicator {
    UIBlurEffect* blurEffect = [[UIBlurEffect alloc] init];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [self.contentView addSubview:self.blurView];
    [self.blurView mas_makeConstraints:^(MASConstraintMaker* make) {
        make.edges.equalTo(self.contentView);
    }];

    self.activityIndicator       = [[UIActivityIndicatorView alloc] init];
    self.activityIndicator.color = [UIColor blackColor];
    [self.blurView.contentView addSubview:self.activityIndicator];
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker* make) {
        make.height.and.width.equalTo(@50);
        make.center.equalTo(self.activityIndicator.superview);
    }];
}

- (void)rememberSettingsFromIB {
    self.paddingAboveDescriptionFromIB = self.paddingConstraintAboveDescription.constant;
    self.paddingBelowDescriptionFromIB = self.paddingConstraintBelowDescription.constant;
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
    [super setImageURL:imageURL];
    if (imageURL) {
        [self restoreImageToFullHeight];
    } else {
        [self collapseImageHeightToZero];
    }
}

- (void)setImage:(MWKImage*)image {
    [super setImage:image];
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

- (void)setSaveableTitle:(MWKTitle*)title savedPageList:(MWKSavedPageList*)savedPageList {
    self.saveButtonController.savedPageList = savedPageList;
    self.saveButtonController.title         = title;
}

@end
