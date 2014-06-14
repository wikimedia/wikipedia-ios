//  Created by Monte Hurd on 6/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "EditSummaryViewController.h"
#import "WikipediaAppUtils.h"
#import "PreviewAndSaveViewController.h"
#import "MenuButton.h"

#import "ModalMenuAndContentViewController.h"

#define MAX_SUMMARY_LENGTH 255

@interface EditSummaryViewController ()

@property (weak, nonatomic) IBOutlet UITextField *summaryTextField;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLineHeightConstraint;

@end

@implementation EditSummaryViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.summaryText = @"";
        self.navBarMode = NAVBAR_MODE_EDIT_WIKITEXT_SUMMARY;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.summaryTextField.attributedPlaceholder =
        [self getAttributedPlaceholderForString:MWLocalizedString(@"edit-summary-field-placeholder-text", nil)];

    self.summaryTextField.textColor = [UIColor darkGrayColor];
    self.summaryTextField.returnKeyType = UIReturnKeyDone;
    self.summaryTextField.delegate = self;

    self.bottomLineHeightConstraint.constant = 1.0f / [UIScreen mainScreen].scale;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self save];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidChange :(NSNotification *)notification
{
    [self updateDoneButtonState];
}

-(void)updateDoneButtonState
{
    ModalMenuAndContentViewController *modalMenuAndContentVC = (ModalMenuAndContentViewController *)self.parentViewController.parentViewController;
    TopMenuViewController *topMenuViewController = modalMenuAndContentVC.topMenuViewController;
    MenuButton *button = (MenuButton *)[topMenuViewController getNavBarItem:NAVBAR_BUTTON_DONE];
    button.enabled = (self.summaryTextField.text.length > 0) ? YES : NO;
}

// From: http://stackoverflow.com/a/1773257
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > MAX_SUMMARY_LENGTH) ? NO : YES;
}

-(NSAttributedString *)getAttributedPlaceholderForString:(NSString *)string
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:string];

    [str addAttribute:NSFontAttributeName
                value:[UIFont systemFontOfSize:12.0]
                range:NSMakeRange(0, str.length)];

    [str addAttribute:NSForegroundColorAttributeName
                value:[UIColor colorWithWhite:0.55 alpha:1.0]
                range:NSMakeRange(0, str.length)];

    return str;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];
    
    [self.summaryTextField becomeFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.summaryTextField.text = self.summaryText;
    
    [self updateDoneButtonState];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:@"UITextFieldTextDidChangeNotification" object:self.summaryTextField];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.summaryTextField resignFirstResponder];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"UITextFieldTextDidChangeNotification"
                                                  object: nil];

    [super viewWillDisappear:animated];
}

- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
            [self hide];
            break;
        case NAVBAR_BUTTON_DONE:
            [self save];
            break;
        default:
            break;
    }
}

-(void)save
{
    NSString *trimmedSummary =
        [self.summaryTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.previewVC.summaryText = trimmedSummary;
    [self hide];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)hide
{
    // Hide this view controller.
    if(!(self.isBeingPresented || self.isBeingDismissed)){
    
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }
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
