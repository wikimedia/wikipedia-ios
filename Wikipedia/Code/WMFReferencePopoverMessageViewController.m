#import "WMFReferencePopoverMessageViewController.h"
#import "Wikipedia-Swift.h"
@import WMF.Swift;

NSString *const WMFReferenceLinkTappedNotification = @"WMFReferenceLinkTappedNotification";

@interface WMFReferencePopoverMessageViewController () <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *horizontalSeparatorHeightConstraint;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) WMFTheme *theme;

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

    if (!self.theme) {
        self.theme = [WMFTheme standard];
    }

    NSAssert(self.textView.scrollEnabled == NO, @"scrollEnabled must be NO for 'preferredContentSize' calculations to correctly account for textView's contentSize height");

    [self.widthConstraint setConstant:self.width];

    [self applyTheme:self.theme];

    self.closeButton.accessibilityLabel = [WMFCommonStrings closeButtonAccessibilityLabel];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.view);
}

- (NSString *)referenceHTMLWithSurroundingHTML {
    NSNumber *fontSize = [[NSUserDefaults standardUserDefaults] wmf_articleFontSizeMultiplier];

    NSString *baseUrl = [self.articleURL absoluteString];
    NSString *layoutDirection = [MWKLanguageLinkController layoutDirectionForContentLanguageCode:self.articleURL.wmf_language];

    return
        [NSString stringWithFormat:@""
                                    "<html>"
                                    "<head>"
                                    "<base href='%@' target='_self'>"
                                    "<style>"
                                    " *{"
                                    "     line-height:27px;"
                                    "     font-family:'-apple-system';"
                                    "     font-size:16px;"
                                    "     -webkit-text-size-adjust:%ld%%;"
                                    "     color:#%@;"
                                    "     text-decoration:none;"
                                    "     direction:%@;"
                                    " }"
                                    " sup {"
                                    "     line-height:12px;"
                                    "     font-size:12px;"
                                    "}"
                                    " sup * {"
                                    "     line-height:12px;"
                                    "     font-size:12px;"
                                    "}"
                                    "</style>"
                                    "</head>"
                                    "<body>"
                                    "%@"
                                    "</body>"
                                    "</html>",
                                   baseUrl, (long)fontSize.integerValue, [self.theme.colors.primaryText wmf_hexStringIncludingAlpha:NO], layoutDirection, self.reference.html];
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
    return [self.view systemLayoutSizeFittingSize:CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric)];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
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

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
    if (self.viewIfLoaded == nil) {
        return;
    }

    self.view.backgroundColor = theme.colors.popoverBackground;

    self.textView.linkTextAttributes = @{NSForegroundColorAttributeName: theme.colors.link};

    [self.textView setAttributedText:[self attributedStringForHTML:[self referenceHTMLWithSurroundingHTML]]];

    self.horizontalSeparatorHeightConstraint.constant = 1.f / [UIScreen mainScreen].scale;

    self.closeButton.tintColor = theme.colors.border;

    self.titleLabel.textColor = theme.colors.secondaryText;

    self.titleLabel.attributedText =
        [[WMFLocalizedStringWithDefaultValue(@"reference-title", nil, nil, @"Reference %1$@", @"Title shown above reference/citation popover. %1$@ is replaced with the reference link text - i.e. '[1]' {{Identical|Reference}}") uppercaseStringWithLocale:[NSLocale currentLocale]]
            attributedStringWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13]}
                       substitutionStrings:@[self.reference.text]
                    substitutionAttributes:@[@{NSForegroundColorAttributeName: theme.colors.primaryText}]];
}

@end
