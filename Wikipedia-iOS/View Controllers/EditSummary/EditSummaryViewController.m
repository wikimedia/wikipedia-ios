//  Created by Monte Hurd on 3/10/14.

#import "EditSummaryViewController.h"

#define DOCK_DISTANCE_FROM_BOTTOM 68.0f
#define MAX_SUMMARY_LENGTH 255

typedef enum {
    DOCK_BOTTOM = 0,
    DOCK_TOP = 1
} EditSummaryDockLocation;

@interface EditSummaryViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;

@property (weak, nonatomic) IBOutlet UIButton *fixedTyposButton;
@property (weak, nonatomic) IBOutlet UIButton *linkedWordsButton;
@property (weak, nonatomic) IBOutlet UIButton *addRemoveInfoButton;

@property (weak, nonatomic) IBOutlet UITextField *summaryTextField;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topDividerHeightConstraint;

@end

@implementation EditSummaryViewController

-(NSString *)getSummary
{
    NSMutableArray *summaryArray = @[].mutableCopy;
    
    if (self.summaryTextField.text && (self.summaryTextField.text.length > 0)) {
        [summaryArray addObject:self.summaryTextField.text];
    }
    if (self.fixedTyposButton.selected) [summaryArray addObject:self.fixedTyposButton.titleLabel.text];
    if (self.linkedWordsButton.selected) [summaryArray addObject:self.linkedWordsButton.titleLabel.text];
    if (self.addRemoveInfoButton.selected) [summaryArray addObject:self.addRemoveInfoButton.titleLabel.text];
    return [summaryArray componentsJoinedByString:@"; "];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Use the pan recognizer to allow the edit summary to be dragged up and down.
    // Works because in the "handlePan:" method the height constraint is updated
    // to increase depending on vertical pan amount.
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.delegate = self;
    [self.view addGestureRecognizer:panRecognizer];
    
    UIColor *buttonTextColor = [UIColor colorWithRed:0.00 green:0.51 blue:0.96 alpha:1.0];
    UIColor *borderColor = [UIColor lightGrayColor];
    CGFloat borderWidth = 1.0f / [UIScreen mainScreen].scale;
    UIEdgeInsets buttonPaddingInset = UIEdgeInsetsMake(8, 10, 8, 10);
    
    void (^setupButton)(UIButton *, NSString *) = ^void(UIButton *button, NSString *title) {
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:buttonTextColor forState:UIControlStateNormal];
        button.layer.borderColor = borderColor.CGColor;
        button.layer.borderWidth = borderWidth;
        button.contentEdgeInsets = buttonPaddingInset;
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    };

    setupButton(self.fixedTyposButton, NSLocalizedString(@"edit-summary-choice-fixed-typos-grammar", nil));
    setupButton(self.linkedWordsButton, NSLocalizedString(@"edit-summary-choice-linked-words", nil));
    setupButton(self.addRemoveInfoButton, NSLocalizedString(@"edit-summary-choice-add-remove-info", nil));
    
    self.aboutLabel.text = NSLocalizedString(@"edit-summary-description", nil);
    self.summaryTextField.placeholder = NSLocalizedString(@"edit-summary-field-placeholder-text", nil);

    self.summaryTextField.textColor = [UIColor darkGrayColor];
    self.summaryTextField.returnKeyType = UIReturnKeyDone;
    self.summaryTextField.delegate = self;
    
    self.topDividerHeightConstraint.constant = borderWidth;
    
    self.navigationItem.hidesBackButton = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(previewWebViewBeganScrolling)
                                                 name: @"PreviewWebViewBeganScrolling"
                                               object: nil];

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self dockAtLocation:DOCK_BOTTOM];
    return YES;
}

-(void)previewWebViewBeganScrolling
{
    [self dockAtLocation:DOCK_BOTTOM];
}

-(void)buttonTapped:(UIButton *)button
{
    button.selected = !button.selected;
    button.backgroundColor = (button.selected) ? [UIColor colorWithRed:0.80 green:0.94 blue:0.91 alpha:1.0] : [UIColor whiteColor];
}

-(void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    static CGFloat originalHeight;
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        originalHeight = self.topConstraint.constant;
        if (self.summaryTextField.isFirstResponder) {
            [self.summaryTextField resignFirstResponder];
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translate = [recognizer translationInView:recognizer.view.superview];
        CGFloat newHeight = originalHeight + translate.y;
        self.topConstraint.constant = newHeight;
        [self.view setNeedsUpdateConstraints];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateFailed ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self dockAtLocation:DOCK_TOP];
}

// From: http://stackoverflow.com/a/1773257
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > MAX_SUMMARY_LENGTH) ? NO : YES;
}

-(void)dockAtLocation:(EditSummaryDockLocation)location
{
    if (location == DOCK_BOTTOM) [self.summaryTextField resignFirstResponder];

    [UIView animateWithDuration: 0.28f
                          delay: 0.0f
                        options: UIViewAnimationOptionTransitionNone
                     animations: ^{
                         switch (location) {
                             case DOCK_TOP:
                                 self.topConstraint.constant = 0.0;
                                 break;
                             case DOCK_BOTTOM:
                                 self.topConstraint.constant = self.parentViewController.view.frame.size.height - DOCK_DISTANCE_FROM_BOTTOM;
                                 break;
                             default:
                                 break;
                         }
                         [self.parentViewController.view layoutIfNeeded];
                     } completion:^(BOOL done){
                     }];
}

-(void)updateViewConstraints
{
    CGFloat initialDistanceFromTop = self.parentViewController.view.frame.size.height - DOCK_DISTANCE_FROM_BOTTOM;
    if (!self.topConstraint) {
    
        self.topConstraint = [NSLayoutConstraint constraintWithItem: self.view
                                                          attribute: NSLayoutAttributeTop
                                                          relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                             toItem: self.parentViewController.view
                                                          attribute: NSLayoutAttributeTop
                                                         multiplier: 1.0f
                                                           constant: initialDistanceFromTop];
        
        [self.parentViewController.view addConstraint:self.topConstraint];

    }
    
    // Enforce vertical scroll limits.
    CGFloat yConstant = self.topConstraint.constant;
    CGFloat constrainedYConstant = fmaxf(yConstant, 0);
    constrainedYConstant = fminf(initialDistanceFromTop, constrainedYConstant);
    
    // Adjust only if it was scrolled out of limits.
    if (yConstant != constrainedYConstant) {
        self.topConstraint.constant = constrainedYConstant;
    }
    
    [super updateViewConstraints];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Ensure edit summary isn't scrolled past its vertical limits after rotate.
    [self.view setNeedsUpdateConstraints];
    
    //[self dockAtLocation:DOCK_BOTTOM];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
