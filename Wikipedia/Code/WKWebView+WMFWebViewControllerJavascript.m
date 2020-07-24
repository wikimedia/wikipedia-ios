#import "WKWebView+WMFWebViewControllerJavascript.h"
@import WMF;
#import "Wikipedia-Swift.h"
#import <WMF/NSURL+WMFLinkParsing.h>

// Some dialects have complex characters, so we use 2 instead of 10
static int const kMinimumTextSelectionLength = 2;

@implementation WKWebView (WMFWebViewControllerJavascript)

- (void)wmf_setTextSize:(NSInteger)textSize {
    [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.windowResizeScroll.recordTopElementAndItsRelativeYOffset(); document.body.style['font-size'] = '%ld%%';", (long)textSize]
           completionHandler:^(id _Nullable obj, NSError *_Nullable error) {
               [self evaluateJavaScript:@"window.wmf.windowResizeScroll.scrollToSamePlaceBeforeResize()" completionHandler:NULL];
           }];
}

- (void)wmf_accessibilityCursorToFragment:(NSString *)fragment {
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.accessibilityCursorToFragment('%@')", fragment] completionHandler:nil];
    }
}

- (void)wmf_highlightLinkID:(NSString *)linkID {
    [self evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('%@').classList.add('reference-highlight');", linkID]
           completionHandler:NULL];
}

- (void)wmf_unHighlightAllLinkIDs {
    [self evaluateJavaScript:[NSString stringWithFormat:@"document.querySelectorAll('.reference-highlight').forEach(e => {e.classList.remove('reference-highlight')});"]
           completionHandler:NULL];
}

- (void)wmf_getSelectedText:(void (^)(NSString *text))completion {
    [self evaluateJavaScript:@"window.getSelection().toString()"
           completionHandler:^(id _Nullable obj, NSError *_Nullable error) {
               if ([obj isKindOfClass:[NSString class]]) {
                   NSString *selectedText = [(NSString *)obj wmf_shareSnippetFromText];
                   selectedText = selectedText.length < kMinimumTextSelectionLength ? @"" : selectedText;
                   completion(selectedText);
               } else {
                   completion(@"");
               }
           }];
}

@end
