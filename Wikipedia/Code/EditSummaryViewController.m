#import "EditSummaryViewController.h"
#import "PreviewAndSaveViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

#define MAX_SUMMARY_LENGTH 255

@interface EditSummaryViewController ()

@property (weak, nonatomic) IBOutlet UITextField *summaryTextField;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLineHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;

@property (strong, nonatomic) UIBarButtonItem *buttonDone;

@end

@implementation EditSummaryViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.summaryText = @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *buttonX = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX target:self action:@selector(closeButtonPressed)];
    self.navigationItem.leftBarButtonItem = buttonX;

    self.buttonDone = [[UIBarButtonItem alloc] initWithTitle:WMFLocalizedStringWithDefaultValue(@"button-done", nil, nil, @"Done", @"Button text for done button used in various places.\n{{Identical|Done}}") style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = self.buttonDone;

    self.placeholderLabel.text = WMFLocalizedStringWithDefaultValue(@"edit-summary-field-placeholder-text", nil, nil, @"Other ways you improved the article", @"Placeholder text which appears initially in the free-form edit summary text box");
    self.placeholderLabel.textAlignment = NSTextAlignmentNatural;
    self.placeholderLabel.font = [UIFont systemFontOfSize:14.0];

    self.summaryTextField.textColor = [UIColor darkGrayColor];
    self.summaryTextField.returnKeyType = UIReturnKeyDone;
    self.summaryTextField.delegate = self;
    self.summaryTextField.textAlignment = NSTextAlignmentNatural;
    self.summaryTextField.font = [UIFont systemFontOfSize:14.0];

    self.bottomLineHeightConstraint.constant = 1.0f / [UIScreen mainScreen].scale;
}

- (void)closeButtonPressed {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self save];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidChange:(NSNotification *)notification {
    [self updatePlaceholderLabelState];
}

- (void)updatePlaceholderLabelState {
    self.placeholderLabel.hidden = ([self.summaryTextField.text length] == 0) ? NO : YES;
}

// From: http://stackoverflow.com/a/1773257
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > MAX_SUMMARY_LENGTH) ? NO : YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.summaryTextField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.summaryTextField.text = self.summaryText;

    [self updatePlaceholderLabelState];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:@"UITextFieldTextDidChangeNotification" object:self.summaryTextField];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.summaryTextField resignFirstResponder];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UITextFieldTextDidChangeNotification"
                                                  object:nil];

    [super viewWillDisappear:animated];
}

- (void)save {
    NSString *trimmedSummary =
        [self.summaryTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.previewVC.summaryText = trimmedSummary;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
