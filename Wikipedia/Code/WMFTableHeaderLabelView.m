#import "WMFTableHeaderLabelView.h"

@interface WMFTableHeaderLabelView ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *trailingConstraint;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

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
