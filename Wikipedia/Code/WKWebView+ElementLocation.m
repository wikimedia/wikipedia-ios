//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WKWebView+ElementLocation.h"

@implementation WKWebView (ElementLocation)

- (void)getScreenRectForHtmlElementWithId:(NSString*)elementId completion:(void (^)(CGRect rect))completion {
    [self getScreenRectForHtmlElementFromJavascriptString:[NSString stringWithFormat:@"window.wmf.elementLocation.getElementRect(document.getElementById('%@'));", elementId]
                                               completion:completion];
}

- (void)getScrollViewRectForHtmlElementWithId:(NSString*)elementId completion:(void (^)(CGRect rect))completion {
    [self getScreenRectForHtmlElementWithId:elementId
                                 completion:^(CGRect rect) {
        completion([self getRectRelativeToScrollView:rect]);
    }];
}

- (void)getScreenRectForHtmlImageWithSrc:(NSString*)src completion:(void (^)(CGRect rect))completion {
    [self getScreenRectForHtmlElementFromJavascriptString:[NSString stringWithFormat:@"window.wmf.elementLocation.getElementRect(window.wmf.elementLocation.getImageWithSrc('%@'));", src]
                                               completion:completion];
}

- (void)getScrollViewRectForHtmlImageWithSrc:(NSString*)src completion:(void (^)(CGRect rect))completion {
    [self getScreenRectForHtmlImageWithSrc:src
                                completion:^(CGRect rect) {
        completion([self getRectRelativeToScrollView:rect]);
    }];
}

- (CGRect)getRectRelativeToScrollView:(CGRect)rect {
    rect.origin =
        CGPointMake(
            rect.origin.x + floor(self.scrollView.contentOffset.x),
            rect.origin.y + floor(self.scrollView.contentOffset.y)
            );
    return rect;
}

- (void)getScreenRectForHtmlElementFromJavascriptString:(NSString*)javascriptString completion:(void (^)(CGRect rect))completion {
    [self evaluateJavaScript:javascriptString
           completionHandler:^(id _Nullable obj, NSError* _Nullable error) {
        if (!error && obj) {
            NSAssert([obj objectForKey:@"X"] &&
                     [obj objectForKey:@"Y"] &&
                     [obj objectForKey:@"Width"] &&
                     [obj objectForKey:@"Height"]
                     , @"Required keys missing from dictionary destined to be converted to a CGRect");
            CGRect rect;
            if (CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)(obj), &rect)) {
                completion(rect);
                return;
            }
        }
        completion(CGRectNull);
    }];
}

- (void)getIndexOfTopOnScreenElementWithPrefix:(NSString*)prefix count:(NSUInteger)count completion:(void (^)(id index, NSError* error))completion {
    [self evaluateJavaScript:[NSString stringWithFormat:@"window.wmf.elementLocation.getIndexOfFirstOnScreenElement('%@', %lu)", prefix, count]
           completionHandler:^(id _Nullable index, NSError* _Nullable error) {
        completion(index, error);
    }];
}

@end
