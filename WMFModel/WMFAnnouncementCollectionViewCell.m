
#import "WMFAnnouncementCollectionViewCell.h"
#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"

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
    NSError *error = nil;
    NSMutableAttributedString *string = [[[NSAttributedString alloc]
              initWithData:[text dataUsingEncoding:NSUTF8StringEncoding]
                   options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
        documentAttributes:nil
                     error:&error] mutableCopy];

    if (error) {
        [self.messageLabel setText:text];
    } else {
        static NSDictionary *attributes;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
            pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
            pStyle.baseWritingDirection = NSWritingDirectionNatural;
            pStyle.lineHeightMultiple = 1.35;
            pStyle.alignment = NSTextAlignmentCenter;
            attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                           NSForegroundColorAttributeName: [UIColor blackColor],
                           NSParagraphStyleAttributeName: pStyle};
        });

        [string addAttributes:attributes range:NSMakeRange(0, string.length)];
        [self.messageLabel setAttributedText:string];
    }
}
- (void)setActionText:(NSString *)text {
    [self.actionButton setTitle:text forState:UIControlStateNormal];
}

- (void)setCaptionHTML:(NSString *)text {
    NSError *error = nil;
    NSMutableAttributedString *string = [[[NSAttributedString alloc]
              initWithData:[text dataUsingEncoding:NSUTF8StringEncoding]
                   options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
        documentAttributes:nil
                     error:&error] mutableCopy];
    if (error) {
        [self.captionTextView setText:text];
    } else {
        static NSDictionary *attributes;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
            pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
            pStyle.baseWritingDirection = NSWritingDirectionNatural;
            pStyle.lineHeightMultiple = 1.35;
            pStyle.alignment = NSTextAlignmentCenter;
            attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                           NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:0x72777D alpha:1.0],
                           NSParagraphStyleAttributeName: pStyle};
        });
        [string addAttributes:attributes range:NSMakeRange(0, string.length)];
        [self.captionTextView setAttributedText:string];
    }
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

+ (CGFloat)estimatedRowHeight {
    return 250;
}

@end
