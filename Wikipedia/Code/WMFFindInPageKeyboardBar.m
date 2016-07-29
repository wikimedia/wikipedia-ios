#import "WMFFindInPageKeyboardBar.h"
#import "UIControl+BlocksKit.h"

@interface WMFFindInPageKeyboardBar() <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIButton *clearButton;
@property (strong, nonatomic) IBOutlet UIButton *previousButton;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIImageView *magnifyImageView;
@property (strong, nonatomic) IBOutlet UILabel *currentMatchLabel;

@property (strong, nonatomic) IBOutlet UITextField *textField;

@end

@implementation WMFFindInPageKeyboardBar

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, 46);
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {
        self.tintColor = [UIColor colorWithRed:0.3373 green:0.3373 blue:0.3373 alpha:1.0];
    }
    return self;
}

- (IBAction)didTouchPrevious{
    [self.delegate keyboardBarPreviousButtonTapped:self];
}

- (IBAction)didTouchNext{
    [self.delegate keyboardBarNextButtonTapped:self];
}

- (IBAction)textFieldDidChange:(UITextField *)textField {
    [self.delegate keyboardBar:self searchTermChanged:textField.text];
    self.clearButton.hidden = (textField.text.length == 0) ? YES : NO;
}

- (IBAction)didTouchClose{
    [self didTouchClear];
    [self.delegate keyboardBarCloseButtonTapped:self];
}

- (IBAction)didTouchClear{
    [self.textField setText:@""];
    [self.delegate keyboardBar:self searchTermChanged:@""];
    [self.delegate keyboardBarClearButtonTapped:self];
    self.clearButton.hidden = YES;
}

- (void)setNumberOfMatches:(NSUInteger)numberOfMatches {
    _numberOfMatches = numberOfMatches;
    [self setCurrentMatchLabelText];
}

- (void)setCurrentCursorIndex:(NSInteger)currentCursorIndex {
    _currentCursorIndex = currentCursorIndex;
    [self setCurrentMatchLabelText];
}

- (void)setCurrentMatchLabelText {
    NSString *labelText = nil;
    if (self.textField.text.length == 0) {
        labelText = @"";
    } else if (self.numberOfMatches > 0 && self.currentCursorIndex == -1) {
        labelText = [NSString stringWithFormat:@"%lu", self.numberOfMatches];
    } else if (self.numberOfMatches == 0) {
        labelText = MWLocalizedString(@"find-in-page-no-matches", nil);
    }else{
        labelText = [NSString stringWithFormat:@"%lu / %lu", self.currentCursorIndex + 1, self.numberOfMatches];
    }
    [self.currentMatchLabel setText:labelText];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self didTouchClose];
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
    [self.textField setText:@""];
}

@end
