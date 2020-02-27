#import "WKWebView+ElementLocation.h"
#import "NSString+WMFExtras.h"

@implementation WKWebView (ElementLocation)

- (void)getScreenRectForHtmlElementWithId:(NSString *)elementId completion:(void (^)(CGRect rect))completion {
    [self getScreenRectForHtmlElementFromJavascriptString:[NSString stringWithFormat:@"window.wmf.elementLocation.getElementRect(document.getElementById('%@'));", [elementId wmf_stringBySanitizingForJavaScript]]
                                               completion:completion];
}

- (void)getScrollViewRectForHtmlElementWithId:(NSString *)elementId completion:(void (^)(CGRect rect))completion {
    [self getScreenRectForHtmlElementWithId:elementId
                                 completion:^(CGRect rect) {
                                     completion([self getRectRelativeToScrollView:rect]);
                                 }];
}


- (CGRect)getRectRelativeToScrollView:(CGRect)rect {
    rect.origin =
        CGPointMake(
            rect.origin.x + floor(self.scrollView.contentOffset.x),
            rect.origin.y + floor(self.scrollView.contentOffset.y));
    return rect;
}

- (void)getScreenRectForHtmlElementFromJavascriptString:(NSString *)javascriptString completion:(void (^)(CGRect rect))completion {
    [self evaluateJavaScript:javascriptString
           completionHandler:^(id _Nullable obj, NSError *_Nullable error) {
               if (!error && obj) {
                   NSAssert([obj objectForKey:@"X"] &&
                                [obj objectForKey:@"Y"] &&
                                [obj objectForKey:@"Width"] &&
                                [obj objectForKey:@"Height"],
                            @"Required keys missing from dictionary destined to be converted to a CGRect");
                   CGRect rect;
                   if (CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)(obj), &rect)) {
                       completion(rect);
                       return;
                   }
               }
               completion(CGRectNull);
           }];
}

@end
