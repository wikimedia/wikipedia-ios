
#import "WMFTableHeaderLabelView.h"

@interface WMFTableHeaderLabelView ()

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *trailingConstraint;

@end

@implementation WMFTableHeaderLabelView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.textLabel.textColor = [UIColor wmf_nearbyDescriptionColor];
}

- (void)setText:(NSString *)text {
    //If its short, display as table view header text
    //If its long, make it read as normal prose
    if (text.length < 50) {
        self.textLabel.text = [text uppercaseString];
    } else {
        self.textLabel.text = text;
    }
}

- (NSString *)text {
    return self.textLabel.text;
}

- (CGFloat)heightWithExpectedWidth:(CGFloat)width {
    self.textLabel.preferredMaxLayoutWidth = width - self.leadingConstraint.constant - self.trailingConstraint.constant;
    return [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
}

@end
