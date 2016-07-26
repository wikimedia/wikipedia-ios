#import "FindInPageKeyboardBar.h"
#import "FindInPageTextField.h"
#import "UIControl+BlocksKit.h"

@interface FindInPageKeyboardBar()

@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIButton *clearButton;
@property (strong, nonatomic) IBOutlet UIButton *previousButton;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIImageView *magnifyImageView;

@end

@implementation FindInPageKeyboardBar

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, 48);
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {
        self.tintColor = [UIColor colorWithRed:0.3373 green:0.3373 blue:0.3373 alpha:1.0];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidChange:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (IBAction)didTouchPrevious{
    [self.delegate findInPagePreviousButtonTapped];
}

- (IBAction)didTouchNext{
    [self.delegate findInPageNextButtonTapped];
}

- (void)textDidChange:(NSNotification*)notification {
    if (notification.object == self.textField) {
        [self.delegate findInPageTermChanged:[[notification object] text] sender:self];
    }
}

- (IBAction)didTouchClose{
    [self didTouchClear];
    [self.delegate findInPageCloseButtonTapped];
}

- (IBAction)didTouchClear{
    [self.textField setText:@""];
    [self.delegate findInPageTermChanged:@"" sender:self];
    [self.delegate findInPageClearButtonTapped];
}

@end
