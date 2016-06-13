//  Created by Monte Hurd on 2/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WKWebView+WMFWebViewControllerJavascript.h"
#import "NSString+WMFHTMLParsing.h"
#import "MWKArticle.h"
#import "MWLanguageInfo.h"
#import "Wikipedia-Swift.h"

// Some dialects have complex characters, so we use 2 instead of 10
static int const kMinimumTextSelectionLength = 2;

@implementation WKWebView (WMFWebViewControllerJavascript)

- (void)wmf_setTextSize:(NSInteger)textSize {
    [self evaluateJavaScript:[NSString stringWithFormat:@"document.querySelector('body').style['-webkit-text-size-adjust'] = '%ld%%';", textSize] completionHandler:NULL];
}

- (void)wmf_collapseTablesForArticle:(MWKArticle*)article {
    [self evaluateJavaScript:[self tableCollapsingJavascriptForArticle:article] completionHandler:nil];
}

- (NSString*)tableCollapsingJavascriptForArticle:(MWKArticle*)article {
    return
        [NSString stringWithFormat:@"window.wmf.transformer.transform('hideTables', document, %d, '%@', '%@', '%@');",
         article.isMain,
         [self apostropheEscapedArticleLanguageLocalizedStringForKey:@"info-box-title" article:article],
         [self apostropheEscapedArticleLanguageLocalizedStringForKey:@"table-title-other" article:article],
         [self apostropheEscapedArticleLanguageLocalizedStringForKey:@"info-box-close-text" article:article]
        ];
}

- (NSString*)apostropheEscapedArticleLanguageLocalizedStringForKey:(NSString*)key article:(MWKArticle*)article {
    return [MWSiteLocalizedString(article.site, key, nil) stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
}

- (void)wmf_setLanguage:(MWLanguageInfo*)languageInfo {
    [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.setLanguage('%@', '%@', '%@')",
                              languageInfo.code,
                              languageInfo.dir,
                              [[UIApplication sharedApplication] wmf_isRTL] ? @"rtl" : @"ltr"
     ] completionHandler:nil];
}

- (void)wmf_setPageProtected {
    [self evaluateJavaScript:@"window.wmf.utilities.setPageProtected()" completionHandler:nil];
}

- (void)wmf_setBottomPadding:(NSInteger)bottomPadding {
    [self evaluateJavaScript:[NSString stringWithFormat:@"document.getElementsByTagName('BODY')[0].style.paddingBottom = '%ldpx';", (long)bottomPadding]
           completionHandler:nil];
}

- (void)wmf_scrollToFragment:(NSString*)fragment {
    [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.scrollToFragment('%@')", fragment] completionHandler:nil];
}

- (void)wmf_accessibilityCursorToFragment:(NSString*)fragment {
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.utilities.accessibilityCursorToFragment('%@')", fragment] completionHandler:nil];
    }
}

- (void)wmf_highlightLinkID:(NSString*)linkID {
    NSString* eval = [NSString stringWithFormat:@"\
                      document.getElementById('%@').oldBackgroundColor = document.getElementById('%@').style.backgroundColor;\
                      document.getElementById('%@').style.backgroundColor = '#999';\
                      document.getElementById('%@').style.borderRadius = 2;\
                      ", linkID, linkID, linkID, linkID];
    [self evaluateJavaScript:eval completionHandler:NULL];
}

- (void)wmf_unHighlightLinkID:(NSString*)linkID {
    NSString* eval = [NSString stringWithFormat:@"\
                      document.getElementById('%@').style.backgroundColor = document.getElementById('%@').oldBackgroundColor;\
                      ", linkID, linkID];
    [self evaluateJavaScript:eval completionHandler:NULL];
}

- (void)wmf_getSelectedText:(void (^)(NSString* text))completion {
    [self evaluateJavaScript:@"window.getSelection().toString()" completionHandler:^(id _Nullable obj, NSError* _Nullable error) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString* selectedText = [(NSString*)obj wmf_shareSnippetFromText];
            selectedText = selectedText.length < kMinimumTextSelectionLength ? @"" : selectedText;
            completion(selectedText);
        } else {
            completion(@"");
        }
    }];
}

@end
