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

@end

@implementation WMFAnnouncementCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.captionTextView.delegate = self;
    self.captionTextView.linkTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor wmf_referencePopoverLinkColor],
        NSUnderlineStyleAttributeName: @1
    };
    self.actionButton.layer.borderColor = self.actionButton.tintColor.CGColor;
    [self.actionButton addTarget:self action:@selector(performAction) forControlEvents:UIControlEventTouchUpInside];
    self.captionTextView.textContainerInset = UIEdgeInsetsZero;
    [self.dismissButton setTitle:MWLocalizedString(@"announcements-dismiss", nil) forState:UIControlStateNormal];
    [self.dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton setNeedsLayout];
    [self.dismissButton layoutIfNeeded];
    [self.dismissButton setTitleColor:[UIColor wmf_777777Color] forState:UIControlStateNormal];

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
        [self.imageView wmf_setImageWithURL:imageURL detectFaces:YES failure:NULL success:NULL];
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

- (void)setCaptionHTML:(NSString *)text {
    NSAttributedString *attributedString = [self attributedStringForCaptionHTML:text];
    if (attributedString) {
        [self.captionTextView setAttributedText:attributedString];
    } else {
        [self.captionTextView setText:text];
    }
    [self.captionTextView setNeedsLayout];
    [self.captionTextView layoutIfNeeded];
}

- (nullable NSAttributedString *)attributedStringForCaptionHTML:(NSString *)text {

    NSError *error = nil;
    NSMutableAttributedString *string = [[[NSAttributedString alloc] initWithData:[text dataUsingEncoding:NSUTF8StringEncoding]
                                                                          options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                               documentAttributes:nil
                                                                            error:&error] mutableCopy];
    if (error) {
        return nil;
    } else {
        NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
        pStyle.lineBreakMode = NSLineBreakByWordWrapping;
        pStyle.baseWritingDirection = NSWritingDirectionNatural;
        pStyle.alignment = NSTextAlignmentCenter;
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote],
                                     NSForegroundColorAttributeName: [UIColor wmf_777777Color],
                                     NSParagraphStyleAttributeName: pStyle};
        [string addAttributes:attributes range:NSMakeRange(0, string.length)];
        return string;
    }
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

+ (CGFloat)estimatedRowHeight {
    return 250;
}

@end
