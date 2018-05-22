#import "WMFTableHeaderFooterLabelView.h"

@import WMF.Swift;

@interface WMFTableHeaderFooterLabelView ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *trailingConstraint;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

@end

@implementation WMFTableHeaderFooterLabelView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self applyTheme:[WMFTheme standard]];
}

- (void)setType:(WMFTableHeaderFooterLabelViewType)type {
    switch (type) {
        case WMFTableHeaderFooterLabelViewType_Header:
            self.topConstraint.constant = 15;
        case WMFTableHeaderFooterLabelViewType_Footer:
            self.topConstraint.constant = 8;
    }
}

- (void)setText:(NSString *)text {
    //If its short, display as table view header text
    //If its long, make it read as normal prose
    if (text.length < 50) {
        self.label.text = [text uppercaseString];
    } else {
        self.label.text = text;
    }
}

- (void)setShortTextAsProse:(NSString *)text {
    self.label.text = text;
}

- (NSString *)text {
    return self.label.text;
}

- (CGFloat)heightWithExpectedWidth:(CGFloat)width {
    self.label.preferredMaxLayoutWidth = width - self.leadingConstraint.constant - self.trailingConstraint.constant;
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
    [super prepareForReuse];
    [self removeAllClearButtonTargets];
    self.clearButtonHidden = YES;
}

- (void)applyTheme:(WMFTheme *)theme {
    self.label.textColor = theme.colors.secondaryText;
    self.contentView.backgroundColor = theme.colors.baseBackground;
    self.clearButton.tintColor = theme.colors.secondaryText;
}

@end
