#import "WMFAnnouncementCollectionViewCell.h"
#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
#import "Wikipedia-Swift.h"

@interface WMFAnnouncementCollectionViewCell () <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIButton *actionButton;
@property (strong, nonatomic) IBOutlet UIButton *dismissButton;
@property (strong, nonatomic) IBOutlet UITextView *captionTextView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@property (strong, nonatomic) WMFTheme *theme;


@end

@implementation WMFAnnouncementCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundView = [UIView new];
    self.selectedBackgroundView = [UIView new];
    
    self.captionTextView.delegate = self;
    [self.actionButton addTarget:self action:@selector(performAction) forControlEvents:UIControlEventTouchUpInside];
    self.captionTextView.textContainerInset = UIEdgeInsetsZero;
    [self.dismissButton setTitle:WMFLocalizedStringWithDefaultValue(@"announcements-dismiss", nil, nil, @"No thanks", @"Button text indicating a user wants to dismiss an announcement\n{{Identical|No thanks}}") forState:UIControlStateNormal];
    [self.dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton setNeedsLayout];
    [self.dismissButton layoutIfNeeded];

    [self wmf_configureSubviewsForDynamicType];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self collapseImageHeightToZero];
    self.messageLabel.attributedText = nil;
    self.captionTextView.attributedText = nil;
    self.messageLabel.text = nil;
    self.captionTextView.text = nil;
    [self.actionButton setTitle:nil forState:UIControlStateNormal];
    self.delegate = nil;
}

#pragma mark - Image

- (void)setImageURL:(NSURL *)imageURL {
    if (imageURL) {
        [self.imageView wmf_setImageWithURL:imageURL
                                detectFaces:YES
                                    failure:^(NSError *_Nonnull error) {
                                    }
                                    success:^{
                                    }];
        [self restoreImageToFullHeight];
    } else {
        [self.imageView wmf_reset];
        [self collapseImageHeightToZero];
    }
}

- (void)collapseImageHeightToZero {
    self.imageHeightConstraint.constant = 0;
}

- (void)restoreImageToFullHeight {
    self.imageHeightConstraint.constant = 150;
}

- (void)setMessageText:(NSString *)text {
    [self.messageLabel setText:text];
}

- (void)setActionText:(NSString *)text {
    [self.actionButton setTitle:text forState:UIControlStateNormal];
}

- (void)setCaption:(NSAttributedString *)text {
    _caption = [text copy];
    NSMutableAttributedString *mutableText = [text mutableCopy];
    if (!mutableText || mutableText.length == 0) {
        self.captionTextView.attributedText = nil;
        return;
    }

    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
    pStyle.lineBreakMode = NSLineBreakByWordWrapping;
    pStyle.baseWritingDirection = NSWritingDirectionNatural;
    pStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote],
                                 NSForegroundColorAttributeName: self.theme.colors.secondaryText,
                                 NSParagraphStyleAttributeName: pStyle};
    [mutableText addAttributes:attributes range:NSMakeRange(0, mutableText.length)];
    self.captionTextView.attributedText = mutableText;
    [self.captionTextView setNeedsLayout];
    [self.captionTextView layoutIfNeeded];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    [self.delegate announcementCell:self didTapLinkURL:URL];
    return NO;
}

- (void)dismiss {
    [self.delegate announcementCellDidTapDismiss:self];
}

- (void)performAction {
    [self.delegate announcementCellDidTapActionButton:self];
}

+ (CGFloat)estimatedRowHeightWithImage:(BOOL)withImage {
    return 250 + (withImage ? 150 : 0);
}

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    self.actionButton.layer.borderColor = theme.colors.link.CGColor;

    self.captionTextView.linkTextAttributes = @{
                                                NSForegroundColorAttributeName: theme.colors.link,
                                                NSUnderlineStyleAttributeName: @1
                                                };
    [self.dismissButton setTitleColor:theme.colors.secondaryText forState:UIControlStateNormal];
    
    self.caption = _caption; // Applies the theme color
    
    self.messageLabel.textColor = theme.colors.primaryText;
    
    self.imageView.backgroundColor = theme.colors.midBackground;
    self.selectedBackgroundView.backgroundColor = theme.colors.midBackground;
    self.backgroundView.backgroundColor = theme.colors.paperBackground;
}

@end
