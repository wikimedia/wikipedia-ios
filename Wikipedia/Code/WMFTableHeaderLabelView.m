#import "WMFTableHeaderLabelView.h"

@interface WMFTableHeaderLabelView ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (strong, nonatomic) IBOutlet UILabel *headerLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *trailingConstraint;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

@end

@implementation WMFTableHeaderLabelView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.headerLabel.textColor = [UIColor wmf_nearbyDescription];
}

- (void)setText:(NSString *)text {
    //If its short, display as table view header text
    //If its long, make it read as normal prose
    if (text.length < 50) {
        self.headerLabel.text = [text uppercaseString];
    } else {
        self.headerLabel.text = text;
    }
}

- (NSString *)text {
    return self.headerLabel.text;
}

- (CGFloat)heightWithExpectedWidth:(CGFloat)width {
    self.headerLabel.preferredMaxLayoutWidth = width - self.leadingConstraint.constant - self.trailingConstraint.constant;
    return [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
}

- (void)setClearButtonHidden:(BOOL)clearButtonHidden {
    if (_clearButtonHidden == clearButtonHidden) {
        return;
    }
    self.clearButton.hidden = clearButtonHidden;
    self.trailingConstraint.constant = clearButtonHidden ? 15 : self.clearButton.bounds.size.width + 15;
    _clearButtonHidden = clearButtonHidden;
}

- (void)setLabelVerticallyCentered:(BOOL)labelVerticallyCentered {
    if (_labelVerticallyCentered == labelVerticallyCentered) {
        return;
    }
    if (labelVerticallyCentered) {
        self.bottomConstraint.constant = 10;
        self.topConstraint.constant = self.bottomConstraint.constant;
    } else {
        self.bottomConstraint.constant = 5;
        self.topConstraint.constant = 15;
    }
    _labelVerticallyCentered = labelVerticallyCentered;
}

- (void)removeAllClearButtonTargets {
    NSSet *allTargets = [self.clearButton allTargets];
    for (id target in allTargets) {
        [self.clearButton removeTarget:target action:NULL forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)addClearButtonTarget:(id)target selector:(SEL)selector {
    [self removeAllClearButtonTargets];
    [self.clearButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}

- (void)prepareForReuse {
    [self removeAllClearButtonTargets];
    self.clearButtonHidden = YES;
}

@end
