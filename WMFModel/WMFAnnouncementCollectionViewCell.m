
#import "WMFAnnouncementCollectionViewCell.h"
#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
@import TTTAttributedLabel;

@interface WMFAnnouncementCollectionViewCell () <TTTAttributedLabelDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIButton *actionButton;
@property (strong, nonatomic) IBOutlet UIButton *dismissButton;
@property (strong, nonatomic) IBOutlet TTTAttributedLabel *captionLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;

@end

@implementation WMFAnnouncementCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.captionLabel.delegate = self;
    self.captionLabel.linkAttributes = @{
        NSForegroundColorAttributeName: [UIColor wmf_referencePopoverLinkColor],
        NSUnderlineStyleAttributeName: @1
    };
    self.actionButton.layer.borderColor = self.actionButton.tintColor.CGColor;
    [self.actionButton addTarget:self action:@selector(performAction) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton setTitle:MWLocalizedString(@"announcements-dismiss", nil) forState:UIControlStateNormal];
    [self.dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton setNeedsLayout];
    [self.dismissButton layoutIfNeeded];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self collapseImageHeightToZero];
    self.messageLabel.attributedText = nil;
    self.captionLabel.text = nil;
    self.messageLabel.text = nil;
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
            pStyle.lineBreakMode = NSLineBreakByWordWrapping;
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
    [self.messageLabel setNeedsLayout];
    [self.messageLabel layoutIfNeeded];
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
        [self.captionLabel setText:text];
    } else {
        static NSDictionary *attributes;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
            pStyle.lineBreakMode = NSLineBreakByWordWrapping;
            pStyle.baseWritingDirection = NSWritingDirectionNatural;
            pStyle.lineHeightMultiple = 1.35;
            pStyle.alignment = NSTextAlignmentCenter;
            attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                           NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:0x72777D alpha:1.0],
                           NSParagraphStyleAttributeName: pStyle};
        });
        [string addAttributes:attributes range:NSMakeRange(0, string.length)];
        [self.captionLabel setText:string];
    }
    [self.captionLabel setNeedsLayout];
    [self.captionLabel layoutIfNeeded];
}

- (void)attributedLabel:(TTTAttributedLabel *)label
    didSelectLinkWithURL:(NSURL *)url {
    [self.delegate announcementCell:self didTapLinkURL:url];
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
