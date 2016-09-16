#import "WMFReferencePopoverMessageViewController.h"
#import "UIColor+WMFHexColor.h"
#import "Wikipedia-Swift.h"

@interface WMFReferencePopoverMessageViewController ()<UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;

@end

@implementation WMFReferencePopoverMessageViewController

-(void)setScrollEnabled:(BOOL)scrollEnabled {
    self.textView.scrollEnabled = scrollEnabled;
}

-(BOOL)scrollEnabled {
    return self.textView.scrollEnabled;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSAssert(self.textView.scrollEnabled == NO, @"scrollEnabled must be NO for 'preferredContentSize' calculations to correctly account for textView's contentSize height");
    
    [self.widthConstraint setConstant:self.width];

    self.textView.linkTextAttributes = @{NSForegroundColorAttributeName:[UIColor wmf_referencePopoverLinkColor]};
    
    [self.textView setAttributedText:[self attributedStringForHTML:[self referenceHTMLWithSurroundingHTML]]];
}

- (NSString*)referenceHTMLWithSurroundingHTML {
    NSNumber *fontSize = [[NSUserDefaults wmf_userDefaults] wmf_readingFontSize];
    
    return
    [NSString stringWithFormat:@""
      "<html>"
      "<head>"
      "<style>"
      " *{"
      "     font-family:'-apple-system';"
      "     font-size:16px;"
      "     -webkit-text-size-adjust:%ld%%;"
      "     color:#%@;"
      "     text-decoration:none;"
      " }"
      "</style>"
      "</head>"
      "<body>"
      "%@"
      "</body></html>", (long)fontSize.integerValue, [[UIColor wmf_referencePopoverTextColor] wmf_hexStringWithAlpha:NO], self.referenceHTML];
}

- (NSAttributedString*)attributedStringForHTML:(NSString*)html {
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
    NSLog(@"\n\nURL = %@\n\n", URL);
    return NO;
}

@end
