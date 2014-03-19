//  Created by Monte Hurd on 3/10/14.

#import "EditSummaryViewController.h"
#import "NavController.h"

#define NAV ((NavController *)self.navigationController)
#define DOCK_DISTANCE_FROM_BOTTOM 68.0f
#define MAX_SUMMARY_LENGTH 255

typedef enum {
    DOCK_BOTTOM = 0,
    DOCK_TOP = 1
} EditSummaryDockLocation;

@interface EditSummaryViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;

@property (weak, nonatomic) IBOutlet UIButton *cannedSummary01;
@property (weak, nonatomic) IBOutlet UIButton *cannedSummary02;
@property (weak, nonatomic) IBOutlet UIButton *cannedSummary03;

@property (weak, nonatomic) IBOutlet UIButton *cannedSummary04;
@property (weak, nonatomic) IBOutlet UIButton *cannedSummary05;
@property (weak, nonatomic) IBOutlet UIButton *cannedSummary06;

@property (weak, nonatomic) IBOutlet UIButton *cannedSummaryOther;

@property (weak, nonatomic) IBOutlet UITextField *summaryTextField;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topDividerHeightConstraint;

@property (nonatomic) CGFloat borderWidth;

@end

@implementation EditSummaryViewController

-(NSString *)getSummary
{
    NSMutableArray *summaryArray = @[].mutableCopy;
    
    if (self.summaryTextField.text && (self.summaryTextField.text.length > 0)) {
        [summaryArray addObject:self.summaryTextField.text];
    }
    if (self.cannedSummary01.selected) [summaryArray addObject:self.cannedSummary01.titleLabel.text];
    if (self.cannedSummary02.selected) [summaryArray addObject:self.cannedSummary02.titleLabel.text];
    if (self.cannedSummary03.selected) [summaryArray addObject:self.cannedSummary03.titleLabel.text];

    if (self.cannedSummary04.selected) [summaryArray addObject:self.cannedSummary04.titleLabel.text];
    if (self.cannedSummary05.selected) [summaryArray addObject:self.cannedSummary05.titleLabel.text];
    if (self.cannedSummary06.selected) [summaryArray addObject:self.cannedSummary06.titleLabel.text];

    return [summaryArray componentsJoinedByString:@"; "];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.borderWidth = 1.0f / [UIScreen mainScreen].scale;
    
    // Use the pan recognizer to allow the edit summary to be dragged up and down.
    // Works because in the "handlePan:" method the height constraint is updated
    // to increase depending on vertical pan amount.
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.delegate = self;
    [self.view addGestureRecognizer:panRecognizer];
    
    [self setupButtons];
    
    self.aboutLabel.text = NSLocalizedString(@"edit-summary-description", nil);
    self.summaryTextField.placeholder = NSLocalizedString(@"edit-summary-field-placeholder-text", nil);

    self.summaryTextField.textColor = [UIColor darkGrayColor];
    self.summaryTextField.returnKeyType = UIReturnKeyDone;
    self.summaryTextField.delegate = self;
    
    self.topDividerHeightConstraint.constant = self.borderWidth;
    
    self.navigationItem.hidesBackButton = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(previewWebViewBeganScrolling)
                                                 name: @"PreviewWebViewBeganScrolling"
                                               object: nil];

}

-(void)setupButtons
{
    UIColor *redTextColor = [UIColor colorWithRed:1.00 green:0.35 blue:0.24 alpha:1.0];
    UIColor *greenTextColor = [UIColor colorWithRed:0.00 green:0.73 blue:0.51 alpha:1.0];
    UIColor *borderColor = [UIColor lightGrayColor];

    [self setupButton: self.cannedSummary01
            withTitle: NSLocalizedString(@"edit-summary-choice-fixed-typos", nil)
            textColor: redTextColor
          borderColor: borderColor
     ];
    
    [self setupButton: self.cannedSummary02
            withTitle: NSLocalizedString(@"edit-summary-choice-grammar", nil)
            textColor: redTextColor
          borderColor: borderColor
     ];

    [self setupButton: self.cannedSummary03
            withTitle: NSLocalizedString(@"edit-summary-choice-fixed-inaccuracy", nil)
            textColor: redTextColor
          borderColor: borderColor
     ];

    [self setupButton: self.cannedSummary04
            withTitle: NSLocalizedString(@"edit-summary-choice-linked-words", nil)
            textColor: greenTextColor
          borderColor: borderColor
     ];

    [self setupButton: self.cannedSummary05
            withTitle: NSLocalizedString(@"edit-summary-choice-added-category", nil)
            textColor: greenTextColor
          borderColor: borderColor
     ];

    [self setupButton: self.cannedSummary06
            withTitle: NSLocalizedString(@"edit-summary-choice-added-critical-info", nil)
            textColor: greenTextColor
          borderColor: borderColor
     ];

    [self setupButton: self.cannedSummaryOther
            withTitle: NSLocalizedString(@"edit-summary-choice-other", nil)
            textColor: [UIColor colorWithRed:0.57 green:0.35 blue:0.25 alpha:1.0]
          borderColor: borderColor
     ];

    self.cannedSummaryOther.hidden = YES;
    self.cannedSummary05.hidden = YES;
}

-(void)setupButton:(UIButton *)button withTitle:(NSString *)title textColor:(UIColor *)textColor borderColor:(UIColor *)borderColor{

    NSAttributedString *(^getAttributedText)(NSString *, UIColor *) = ^NSAttributedString *(NSString *title, UIColor *textColor) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        //paragraphStyle.lineSpacing = 2.0f;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:title attributes:nil];
        NSRange wholeRange = NSMakeRange(0, title.length);
        
        [attStr beginEditing];
        [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
        [attStr addAttribute:NSForegroundColorAttributeName value:textColor range:wholeRange];
        [attStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10.0f] range:wholeRange];
        [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
        [attStr addAttribute:NSKernAttributeName value:@1.0f range:wholeRange];
        [attStr endEditing];
        
        return attStr;
    };

[button setAttributedTitle:getAttributedText(title, textColor) forState:UIControlStateNormal];

    CGFloat borderWidth = self.borderWidth;
    UIEdgeInsets buttonPaddingInset = UIEdgeInsetsMake(5, 12, 5, 12);

        button.layer.borderColor = borderColor.CGColor;
        button.layer.borderWidth = borderWidth;
        button.contentEdgeInsets = buttonPaddingInset;
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];

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
    if (button == self.cannedSummaryOther) {
        [self.summaryTextField becomeFirstResponder];
        return;
    }

    button.selected = !button.selected;
    button.backgroundColor = (button.selected) ? [UIColor colorWithWhite:0.9f alpha:1.0f] : [UIColor whiteColor];
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
        CGFloat newYOffset = originalHeight + translate.y;
        
        newYOffset = fminf(newYOffset, [self getDockingYOffset]);

        self.topConstraint.constant = newYOffset;
        [self.view setNeedsUpdateConstraints];
        
        [self updateNavBar];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateFailed ||
        recognizer.state == UIGestureRecognizerStateCancelled)
    {
    }
}

-(void)updateNavBar
{
    NavBarMode newNavBarMode = ([self isDockedAtBottom])
        ? NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW
        : NAVBAR_MODE_EDIT_WIKITEXT_SUMMARY;
    if(NAV.navBarMode != newNavBarMode) NAV.navBarMode = newNavBarMode;
}

-(BOOL)isDockedAtBottom
{
    return (self.topConstraint.constant == ([self getDockingYOffset])) ? YES : NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self dockAtLocation:DOCK_TOP];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.summaryTextField resignFirstResponder];
    [super viewWillDisappear:animated];
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
                                 self.topConstraint.constant = [self getDockingYOffset];
                                 break;
                             default:
                                 break;
                         }
                         [self.parentViewController.view layoutIfNeeded];
                     } completion:^(BOOL done){
                     }];
    [self updateNavBar];
}

-(CGFloat)getDockingYOffset
{
    return self.parentViewController.view.frame.size.height - DOCK_DISTANCE_FROM_BOTTOM;
}

-(void)updateViewConstraints
{
    CGFloat initialDistanceFromTop = [self getDockingYOffset];
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
    
    [self dockAtLocation:DOCK_BOTTOM];
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
