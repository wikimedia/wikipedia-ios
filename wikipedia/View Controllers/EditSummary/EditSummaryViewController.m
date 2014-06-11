//  Created by Monte Hurd on 3/10/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "EditSummaryViewController.h"
#import "WikipediaAppUtils.h"
#import "CenterNavController.h"
#import "Defines.h"
#import "WMF_Colors.h"
#import "EditSummaryHandleView.h"

#import "RootViewController.h"
#import "TopMenuViewController.h"

#define MAX_SUMMARY_LENGTH 255

typedef enum {
    DOCK_BOTTOM = 0,
    DOCK_TOP = 1
} EditSummaryDockLocation;

@interface EditSummaryViewController ()

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;

@property (weak, nonatomic) IBOutlet UIButton *cannedSummary01;
@property (weak, nonatomic) IBOutlet UIButton *cannedSummary02;
@property (weak, nonatomic) IBOutlet UIButton *cannedSummary03;

@property (weak, nonatomic) IBOutlet UIButton *cannedSummary04;
@property (weak, nonatomic) IBOutlet UIButton *cannedSummary05;
@property (weak, nonatomic) IBOutlet UIButton *cannedSummary06;
@property (weak, nonatomic) IBOutlet UIButton *cannedSummary07;

@property (weak, nonatomic) IBOutlet UITextField *summaryTextField;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topDividerHeightConstraint;

@property (nonatomic) CGFloat borderWidth;

@property (weak, nonatomic) IBOutlet UIView *editSummaryContainerView;

@property (nonatomic) CGFloat origHandleHeightConstant;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *handleHeightConstraint;

@property (weak, nonatomic) IBOutlet EditSummaryHandleView *handleView;

@end

@implementation EditSummaryViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

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
    if (self.cannedSummary07.selected) [summaryArray addObject:self.cannedSummary07.titleLabel.text];

    return [summaryArray componentsJoinedByString:@"; "];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.origHandleHeightConstant = self.handleHeightConstraint.constant;
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    self.borderWidth = 1.0f / [UIScreen mainScreen].scale;
    
    // Use the pan recognizer to allow the edit summary to be dragged up and down.
    // Works because in the "handlePan:" method the height constraint is updated
    // to increase depending on vertical pan amount.
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.delegate = self;
    [self.view addGestureRecognizer:panRecognizer];
    
    [self setupButtons];
    
    self.aboutLabel.text = MWLocalizedString(@"edit-summary-description", nil);

    self.summaryTextField.attributedPlaceholder =
        [self getAttributedPlaceholderForString:MWLocalizedString(@"edit-summary-field-placeholder-text", nil)];

    self.summaryTextField.textColor = [UIColor darkGrayColor];
    self.summaryTextField.returnKeyType = UIReturnKeyDone;
    self.summaryTextField.delegate = self;
    
    self.topDividerHeightConstraint.constant = self.borderWidth;
    
    self.navigationItem.hidesBackButton = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(previewWebViewBeganScrolling)
                                                 name: @"PreviewWebViewBeganScrolling"
                                               object: nil];

    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)]];

    [self.handleView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTapped)]];
}

-(NSAttributedString *)getAttributedPlaceholderForString:(NSString *)string
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:string];

    [str addAttribute:NSFontAttributeName
                value:[UIFont systemFontOfSize:12.0]
                range:NSMakeRange(0, str.length)];

    [str addAttribute:NSForegroundColorAttributeName
                value:[UIColor colorWithWhite:0.33 alpha:1.0]
                range:NSMakeRange(0, str.length)];

    return str;
}

-(void)viewTapped:(id)sender
{
    if ([self isDockedAtBottom]) {
        [self dockAtLocation:DOCK_TOP];
    }else if (self.summaryTextField.isFirstResponder){
        [self.summaryTextField resignFirstResponder];
    }
}

-(void)handleViewTapped
{
    [self dockAtLocation:[self isDockedAtBottom] ? DOCK_TOP : DOCK_BOTTOM];
}

-(void)setupButtons
{
    UIColor *topColor = WMF_COLOR_GREEN;
    UIColor *bottomColor = WMF_COLOR_GREEN;

    [self setupButton: self.cannedSummary01
            withTitle: MWLocalizedString(@"edit-summary-choice-fixed-typos", nil)
                color: topColor
     ];
    
    [self setupButton: self.cannedSummary02
            withTitle: MWLocalizedString(@"edit-summary-choice-fixed-grammar", nil)
                color: topColor
     ];
    
    [self setupButton: self.cannedSummary03
            withTitle: MWLocalizedString(@"edit-summary-choice-fixed-inaccuracy", nil)
                color: topColor
     ];
    
    [self setupButton: self.cannedSummary04
            withTitle: MWLocalizedString(@"edit-summary-choice-linked-words", nil)
                color: bottomColor
     ];
    
    [self setupButton: self.cannedSummary05
            withTitle: MWLocalizedString(@"edit-summary-choice-added-clarification", nil)
                color: bottomColor
     ];
    
    [self setupButton: self.cannedSummary06
            withTitle: MWLocalizedString(@"edit-summary-choice-added-missing-info", nil)
                color: bottomColor
     ];
    
    [self setupButton: self.cannedSummary07
            withTitle: MWLocalizedString(@"edit-summary-choice-fixed-styling", nil)
                color: topColor
     ];
}

-(void)setupButton:(UIButton *)button withTitle:(NSString *)title color:(UIColor *)color{

    NSAttributedString *(^getAttributedText)(NSString *, UIColor *) = ^NSAttributedString *(NSString *title, UIColor *textColor) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        //paragraphStyle.lineSpacing = 2.0f;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:title attributes:nil];
        NSRange wholeRange = NSMakeRange(0, title.length);
        
        [attStr beginEditing];
        [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
        [attStr addAttribute:NSForegroundColorAttributeName value:textColor range:wholeRange];
        [attStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13.0f] range:wholeRange];
        [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
        [attStr addAttribute:NSKernAttributeName value:@1.0f range:wholeRange];
        [attStr endEditing];
        
        return attStr;
    };

    [button setAttributedTitle:getAttributedText(title, color) forState:UIControlStateNormal];
    [button setAttributedTitle:getAttributedText(title, [UIColor whiteColor]) forState:UIControlStateSelected];

    CGFloat borderWidth = self.borderWidth;
    UIEdgeInsets buttonPaddingInset = UIEdgeInsetsMake(10, 12, 10, 12);

    button.layer.borderColor = color.CGColor;
    button.layer.borderWidth = borderWidth;
    button.contentEdgeInsets = buttonPaddingInset;
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    button.backgroundColor = [UIColor whiteColor];
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
    button.backgroundColor = (button.selected) ? [self getButtonAttributedTextColor:button] : [UIColor whiteColor];

    if (self.summaryTextField.isFirstResponder){
        [self.summaryTextField resignFirstResponder];
    }
}

-(UIColor *)getButtonAttributedTextColor:(UIButton *)button
{
    // Return the button's UIControlStateNormal attributed text color.
    NSRange effectiveRange = NSMakeRange(0, 0);
    NSAttributedString *attributedString = [button attributedTitleForState:UIControlStateNormal];
    id attributeValue = [attributedString attribute: NSForegroundColorAttributeName
                                                  atIndex: NSMaxRange(effectiveRange)
                                           effectiveRange: &effectiveRange];
    return (attributeValue) ? ((UIColor *)attributeValue) : [UIColor whiteColor];
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
    
    if(ROOT.topMenuViewController.navBarMode != newNavBarMode){
        ROOT.topMenuViewController.navBarMode = newNavBarMode;
    }
    
    [self adjustHandleHeightAnimated];
}

-(void)adjustHandleHeightAnimated
{
    [UIView animateWithDuration: 0.08f
                          delay: 0.0f
                        options: UIViewAnimationOptionTransitionNone
                     animations: ^{
                         
                         if ([self isDockedAtBottom]) {
                            self.handleHeightConstraint.constant = self.origHandleHeightConstant;
                            self.handleView.state = EDIT_SUMMARY_HANDLE_BOTTOM;
                         }else{
                            self.handleHeightConstraint.constant = self.origHandleHeightConstant * 1.4f;
                            self.handleView.state = EDIT_SUMMARY_HANDLE_TOP;
                         }
                         
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL done){
                     }];
}

-(BOOL)isDockedAtBottom
{
    return (self.topConstraint.constant == ([self getDockingYOffset])) ? YES : NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    BOOL wasDockedAtBottom = [self isDockedAtBottom];
    
    // Scroll the edit summary panel to top. Reminder: this changes what's returned
    // from "isDockedAtBottom" - that's why the value was pulled out into
    // "wasDockedAtBottom" above.
    [self dockAtLocation:DOCK_TOP];

    // Only raise the keyboard if tap on text field occured after edit summary
    // panel has been raised from bottom dock location. Allows user to see canned edit
    // summary options before they're hidden by the keyboard.
    return !wasDockedAtBottom;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.summaryTextField resignFirstResponder];
    [super viewWillDisappear:animated];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGFloat initialDistanceFromTop = [self getDockingYOffset];
    self.topConstraint.constant = initialDistanceFromTop;
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
    return self.parentViewController.view.frame.size.height - EDIT_SUMMARY_DOCK_DISTANCE_FROM_BOTTOM;
}

-(void)updateViewConstraints
{
    // Enforce vertical scroll limits.
    CGFloat distanceFromTop = self.topConstraint.constant;

    if (distanceFromTop < 0) {
        
        CGPoint containerBottomOffset =
            [self.editSummaryContainerView convertPoint: CGPointMake(0, self.editSummaryContainerView.frame.size.height)
                                                                             toView: self.view];
        
        // When device is landscape, the editSummaryContainerView may be taller than the screen, so allow
        // the edit summary panel to be scrolled up as far as necessary to allow the bottom of the
        // editSummaryContainerView to be scrolled completely on screen. Otherwise some canned edit
        // summaries won't be selectable!
        CGFloat containerBottomExtraVerticalScrollMarginNeeded =
            fminf((self.parentViewController.view.frame.size.height - containerBottomOffset.y), 0);
        
        distanceFromTop = fmaxf(distanceFromTop, containerBottomExtraVerticalScrollMarginNeeded);
        
        self.topConstraint.constant = distanceFromTop;
    }

    [super updateViewConstraints];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // The view's dimensions have been updated by the time "willAnimateRotationToInterfaceOrientation"
    // is called. So dock the edit summary panel at bottom - this will cause it to animate to docking
    // position as part of rotation animation.
    self.topConstraint.constant = [self getDockingYOffset];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // This prevents a "Unable to simultaneously satisfy constraints." warning which happens if
    // device is rotated back and forth.
    
    // "willAnimateRotationToInterfaceOrientation" sets self.topConstraint.constant so it's ok to
    // set it to 1 here.
    
    self.topConstraint.constant = 1;
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (ROOT.topMenuViewController.navBarMode == NAVBAR_MODE_EDIT_WIKITEXT_SUMMARY) {
        [self updateNavBar];
    }

    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
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
