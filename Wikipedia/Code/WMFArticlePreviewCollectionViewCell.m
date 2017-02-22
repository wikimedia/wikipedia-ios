#import "WMFArticlePreviewCollectionViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIButton+WMFButton.h"
#import "WMFSaveButtonController.h"
#import "MWKImage.h"
#import "UITableViewCell+SelectedBackground.h"
#import <Masonry/Masonry.h>
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"
#import "WMFLeadingImageTrailingTextButton.h"
#import "Wikipedia-Swift.h"

@interface WMFArticlePreviewCollectionViewCell ()

@property (strong, nonatomic) IBOutlet UILabel *snippetLabel;
@property (strong, nonatomic) IBOutlet WMFLeadingImageTrailingTextButton *saveButton;

@property (strong, nonatomic, readwrite) WMFSaveButtonController *saveButtonController;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *paddingConstraintLeading;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *paddingConstraintTrailing;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *paddingConstraintAboveDescription;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *paddingConstraintBelowDescription;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;

@property (strong, nonatomic) UIVisualEffectView *blurView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@property (nonatomic) CGFloat paddingAboveDescriptionFromIB;
@property (nonatomic) CGFloat paddingBelowDescriptionFromIB;

@end

@implementation WMFArticlePreviewCollectionViewCell

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
    self.snippetLabel.text = nil;
    self.saveButtonController.url = nil;
    self.saveButtonController.savedPageList = nil;
    self.loading = NO;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self rememberSettingsFromIB];
    self.saveButton.tintColor = [UIColor wmf_blueTintColor];
    [self.saveButton configureAsSaveButton];
    self.saveButtonController.control = self.saveButton;
    [self wmf_makeCellDividerBeEdgeToEdge];
    [self setupBlurViewAndLoadingIndicator];
    self.loading = NO;
    [self wmf_configureSubviewsForDynamicType];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    UIFont *titleLabelFont = [UIFont wmf_preferredFontForFontFamily:WMFFontFamilyGeorgia withTextStyle:UIFontTextStyleTitle1 compatibleWithTraitCollection:self.traitCollection];
    self.titleLabel.font = titleLabelFont;
}

- (void)setupBlurViewAndLoadingIndicator {
    UIBlurEffect *blurEffect = [[UIBlurEffect alloc] init];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [self.contentView addSubview:self.blurView];
    [self.blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];

    self.activityIndicator = [[UIActivityIndicatorView alloc] init];
    self.activityIndicator.color = [UIColor blackColor];
    [self.blurView.contentView addSubview:self.activityIndicator];
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(@50);
        make.center.equalTo(self.activityIndicator.superview);
    }];
}

- (void)rememberSettingsFromIB {
    self.paddingAboveDescriptionFromIB = self.paddingConstraintAboveDescription.constant;
    self.paddingBelowDescriptionFromIB = self.paddingConstraintBelowDescription.constant;
}

#pragma mark - Description

- (void)setDescriptionText:(NSString *)descriptionText {
    self.descriptionLabel.text = descriptionText;
    if (self.descriptionLabel.text.length == 0) {
        [self removeDescriptionVerticalPadding];
    } else {
        [self restoreDescriptionVerticalPadding];
    }
}

- (void)removeDescriptionVerticalPadding {
    self.paddingConstraintAboveDescription.constant = 0.0;
    self.paddingConstraintBelowDescription.constant = 6.0;
}

- (void)restoreDescriptionVerticalPadding {
    self.paddingConstraintAboveDescription.constant = self.paddingAboveDescriptionFromIB;
    self.paddingConstraintBelowDescription.constant = self.paddingBelowDescriptionFromIB;
}

#pragma mark - Snippet

- (void)updateSnippetLabel {
    if (!self.snippetText.length) {
        self.snippetLabel.text = nil;
        return;
    }
    self.snippetLabel.text = self.snippetText;
}

- (void)setSnippetText:(NSString *)snippetText {
    _snippetText = [snippetText copy];
    [self updateSnippetLabel];
}

#pragma mark - Image

- (void)setImageURL:(NSURL *)imageURL failure:(nonnull WMFErrorHandler)failure success:(nonnull WMFSuccessHandler)success {
    [super setImageURL:imageURL failure:failure success:success];
    if (imageURL) {
        [self restoreImageToFullHeight];
    } else {
        [self collapseImageHeightToZero];
    }
}

- (void)setImage:(MWKImage *)image failure:(nonnull WMFErrorHandler)failure success:(nonnull WMFSuccessHandler)success {
    [super setImage:image failure:failure success:success];
    if (image) {
        [self restoreImageToFullHeight];
    } else {
        [self collapseImageHeightToZero];
    }
}

- (void)collapseImageHeightToZero {
    if (self.imageHeightConstraint.constant == 0) {
        return;
    }
    self.imageHeightConstraint.constant = 0;
}

- (void)restoreImageToFullHeight {
    CGFloat sixteenByNineHeight = [self sixteenByNineImageHeight];
    if (self.imageHeightConstraint.constant == sixteenByNineHeight) {
        return;
    }
    self.imageHeightConstraint.constant = sixteenByNineHeight;
}

- (CGFloat)sixteenByNineImageHeight {
    CGFloat horizontalPadding = self.paddingConstraintLeading.constant + self.paddingConstraintTrailing.constant;
    CGFloat ratio = (9.0 / 16.0);
    return round((self.bounds.size.width - horizontalPadding) * ratio);
}

#pragma mark - Saving

- (WMFSaveButtonController *)saveButtonController {
    if (!_saveButtonController) {
        self.saveButtonController = [[WMFSaveButtonController alloc] init];
    }
    return _saveButtonController;
}

- (void)setSaveableURL:(NSURL *)url savedPageList:(MWKSavedPageList *)savedPageList {
    self.saveButtonController.savedPageList = savedPageList;
    self.saveButtonController.url = url;
}

#pragma mark - Height Estimation

+ (CGFloat)estimatedRowHeightWithImage:(BOOL)withImage {
    return withImage ? 420 : 232;
}

@end
