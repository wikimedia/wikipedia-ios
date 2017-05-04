#import "WMFFindInPageKeyboardBar.h"

@interface WMFFindInPageKeyboardBar () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIButton *clearButton;
@property (strong, nonatomic) IBOutlet UIButton *previousButton;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIImageView *magnifyImageView;
@property (strong, nonatomic) IBOutlet UILabel *currentMatchLabel;

@property (strong, nonatomic) IBOutlet UITextField *textField;

@end

@implementation WMFFindInPageKeyboardBar

- (void)awakeFromNib {
    [super awakeFromNib];
    [self hideUndoRedoIcons];
    self.previousButton.enabled = NO;
    self.nextButton.enabled = NO;
}

- (void)hideUndoRedoIcons {
    if ([self.textField respondsToSelector:@selector(inputAssistantItem)]) {
        self.textField.inputAssistantItem.leadingBarButtonGroups = @[];
        self.textField.inputAssistantItem.trailingBarButtonGroups = @[];
    }
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, 46);
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.tintColor = [UIColor colorWithRed:0.3373 green:0.3373 blue:0.3373 alpha:1.0];
    }
    return self;
}

- (IBAction)didTouchPrevious {
    [self.delegate keyboardBarPreviousButtonTapped:self];
}

- (IBAction)didTouchNext {
    [self.delegate keyboardBarNextButtonTapped:self];
}

- (IBAction)textFieldDidChange:(UITextField *)textField {
    [self.delegate keyboardBar:self searchTermChanged:textField.text];
    self.clearButton.hidden = (textField.text.length == 0) ? YES : NO;
}

- (IBAction)didTouchClose {
    [self.delegate keyboardBarCloseButtonTapped:self];
}

- (IBAction)didTouchClear {
    [self.delegate keyboardBarClearButtonTapped:self];
    if (![self isVisible]) {
        [self show];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self hide];
    return YES;
}

- (BOOL)isVisible {
    return [self.textField isFirstResponder];
}

- (void)show {
    [self.textField becomeFirstResponder];
}

- (void)hide {
    [self.textField resignFirstResponder];
}

- (void)reset {
    [self.textField setText:nil];
    [self.currentMatchLabel setText:nil];
    self.clearButton.hidden = YES;
}

- (void)updateForCurrentMatchIndex:(NSInteger)index matchesCount:(NSUInteger)count {
    [self updateLabelTextForCurrentMatchIndex:index matchesCount:count];
    [self updatePreviousNextButtonsEnabledForMatchesCount:count];
}

- (void)updatePreviousNextButtonsEnabledForMatchesCount:(NSUInteger)count {
    if (count < 2) {
        self.previousButton.enabled = NO;
        self.nextButton.enabled = NO;
    } else {
        self.previousButton.enabled = YES;
        self.nextButton.enabled = YES;
    }
}

- (void)updateLabelTextForCurrentMatchIndex:(NSInteger)index matchesCount:(NSUInteger)count {
    NSString *labelText = nil;
    if (self.textField.text.length == 0) {
        labelText = nil;
    } else if (count > 0 && index == -1) {
        labelText = [NSString localizedStringWithFormat:@"%lu", (unsigned long)count];
    } else {
        NSString *format = WMFLocalizedStringWithDefaultValue(@"find-in-page-number-matches", nil, nil, @"%1$d / %2$d", @"Displayed to indicate how many matches were found even if no matches. Separator can be customized depending on the language. %1$d is replaced with the numerator, %2$d is replaced with the denominator.");
        labelText = [NSString localizedStringWithFormat:format, index + 1, count];
    }
    [self.currentMatchLabel setText:labelText];
}

@end
