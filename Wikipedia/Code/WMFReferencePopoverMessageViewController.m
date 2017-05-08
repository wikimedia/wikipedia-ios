#import "WMFReferencePopoverMessageViewController.h"
#import "WebViewController+WMFReferencePopover.h"
#import "UIColor+WMFHexColor.h"
#import "Wikipedia-Swift.h"

@interface WMFReferencePopoverMessageViewController () <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *horizontalSeparatorHeightConstraint;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation WMFReferencePopoverMessageViewController

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    self.textView.scrollEnabled = scrollEnabled;
}

- (void)scrollToTop {
    [self.textView setContentOffset:CGPointZero animated:NO];
}

- (BOOL)scrollEnabled {
    return self.textView.scrollEnabled;
}

- (void)setWidth:(CGFloat)width {
    _width = width;
    [self.widthConstraint setConstant:width];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSAssert(self.textView.scrollEnabled == NO, @"scrollEnabled must be NO for 'preferredContentSize' calculations to correctly account for textView's contentSize height");

    [self.widthConstraint setConstant:self.width];

    self.textView.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor wmf_referencePopoverLink]};

    [self.textView setAttributedText:[self attributedStringForHTML:[self referenceHTMLWithSurroundingHTML]]];

    self.horizontalSeparatorHeightConstraint.constant = 1.f / [UIScreen mainScreen].scale;

    self.closeButton.tintColor = [UIColor wmf_lightGray];

    self.titleLabel.attributedText =
        [[WMFLocalizedStringWithDefaultValue(@"reference-title", nil, nil, @"Reference %1$@", @"Title shown above reference/citation popover. %1$@ is replaced with the reference link text - i.e. '[1]'\n{{Identical|Reference}}") uppercaseStringWithLocale:[NSLocale currentLocale]]
            attributedStringWithAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:13] }
                       substitutionStrings:@[self.reference.text]
                    substitutionAttributes:@[@{NSForegroundColorAttributeName: [UIColor blackColor]}]];
}

- (NSString *)referenceHTMLWithSurroundingHTML {
    NSNumber *fontSize = [[NSUserDefaults wmf_userDefaults] wmf_articleFontSizeMultiplier];

    NSString *domain = [SessionSingleton sharedInstance].currentArticleSiteURL.wmf_language;
    MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:domain];
    NSString *baseUrl = [NSString stringWithFormat:@"https://%@.wikipedia.org/", languageInfo.code];

    return
        [NSString stringWithFormat:@""
                                    "<html>"
                                    "<head>"
                                    "<base href='%@' target='_self'>"
                                    "<style>"
                                    " *{"
                                    "     font-family:'-apple-system';"
                                    "     font-size:16px;"
                                    "     -webkit-text-size-adjust:%ld%%;"
                                    "     color:#%@;"
                                    "     text-decoration:none;"
                                    "     direction:%@;"
                                    " }"
                                    "</style>"
                                    "</head>"
                                    "<body>"
                                    "%@"
                                    "</body>"
                                    "</html>",
                                   baseUrl, (long)fontSize.integerValue, [[UIColor wmf_referencePopoverText] wmf_hexStringIncludingAlpha:NO], languageInfo.dir, self.reference.html];
}

- (NSAttributedString *)attributedStringForHTML:(NSString *)html {
    return
        [[NSAttributedString alloc] initWithData:[html dataUsingEncoding:NSUnicodeStringEncoding]
                                         options:@{
                                             NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                             NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                                         }
                              documentAttributes:nil
                                           error:nil];
}

- (CGSize)preferredContentSize {
    // Make the popover's dimensions result from the storyboard constraints, i.e. respect
    // dynamic height for localized strings which end up being long enough to wrap lines, etc.
    // Works with both iOS 8 and 9.
    return [self.view systemLayoutSizeFittingSize:CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric)];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFReferenceLinkTappedNotification object:URL];
    return NO;
}

- (IBAction)dismiss {
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)accessibilityPerformEscape {
    [self dismiss];
    return true;
}

@end
