//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+ElementLocation.h"
#import "UIWebView+WMFJavascriptContext.h"

@implementation WKWebView (ElementLocation)

//- (CGPoint)getScreenCoordsForHtmlImageWithSrc:(NSString*)src {
//    NSString* strToEval =
//        [NSString stringWithFormat:@"window.elementLocation.getElementRectAsJson(window.elementLocation.getImageWithSrc('%@'));", src];
//    NSString* jsonString = [self stringByEvaluatingJavaScriptFromString:strToEval];
//    if (jsonString.length == 0) {
//        return CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
//    }
//    NSData* jsonData       = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//    NSError* error         = nil;
//    NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
//    if (error) {
//        return CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
//    }
//    NSString* top  = (NSString*)jsonDict[@"top"];
//    NSString* left = (NSString*)jsonDict[@"left"];
//
//    void (^ zeroOutNulls)(NSString**) = ^(NSString** str){
//        if ([*str isMemberOfClass :[NSNull class]]) {
//            *str = @"0";
//        }
//    };
//    zeroOutNulls(&top);
//    zeroOutNulls(&left);
//
//    return CGPointMake(left.floatValue, top.floatValue);
//}

//- (CGPoint)getWebViewCoordsForHtmlImageWithSrc:(NSString*)src {
//    CGPoint p = [self getScreenCoordsForHtmlImageWithSrc:src];
//
//    return CGPointMake(
//        p.x + floor(self.scrollView.contentOffset.x),
//        p.y + floor(self.scrollView.contentOffset.y)
//        );
//}

- (void)getScreenRectForHtmlElementWithId:(NSString*)elementId completion:(void (^)(CGRect rect))completion {
    NSString* strToEval =
        [NSString stringWithFormat:@"window.elementLocation.getElementRectAsJson(document.getElementById('%@'));", elementId];


    [self evaluateJavaScript:strToEval completionHandler:^(id _Nullable obj, NSError* _Nullable error) {
        NSString* jsonString = obj;
        if (error) {
            completion(CGRectNull);
            return;
        }
        NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error) {
            completion(CGRectNull);
            return;
        }

        NSString* top = (NSString*)jsonDict[@"top"];
        NSString* left = (NSString*)jsonDict[@"left"];
        NSString* width = (NSString*)jsonDict[@"width"];
        NSString* height = (NSString*)jsonDict[@"height"];

        void (^ zeroOutNulls)(NSString**) = ^(NSString** str){
            if ([*str isMemberOfClass :[NSNull class]]) {
                *str = @"0";
            }
        };
        zeroOutNulls(&top);
        zeroOutNulls(&left);
        zeroOutNulls(&width);
        zeroOutNulls(&height);

        completion(CGRectMake(left.floatValue, top.floatValue, width.floatValue, height.floatValue));
    }];
}

- (void)getWebViewRectForHtmlElementWithId:(NSString*)elementId completion:(void (^)(CGRect rect))completion {
    [self getScreenRectForHtmlElementWithId:elementId completion:^(CGRect rect) {
        CGPoint p = CGPointMake(
            rect.origin.x + floor(self.scrollView.contentOffset.x),
            rect.origin.y + floor(self.scrollView.contentOffset.y)
            );
        rect.origin = p;
        completion(rect);
    }];
}

/**
 *  Checks all html elements in the web view which have id's of format prefix string followed
 *  by count index (if prefix is "things_" and count is 3 it will check "thing_0", "thing_1"
 *  and "thing_2") to see if they are onscreen. Returns index of first one found to be so.
 */
- (NSInteger)getIndexOfTopOnScreenElementWithPrefix:(NSString*)prefix count:(NSUInteger)count {
    JSValue* location =
        [[self wmf_strictValueForKey:@"elementLocation"] invokeMethod:@"getIndexOfFirstOnScreenElement"
                                                        withArguments:@[prefix, @(count)]];
    if (!location) {
        DDLogWarn(@"Unable to query webview %@ for location of element for %@ ", self, prefix);
        return NSNotFound;
    }
    NSInteger index = location.toInt32;
    return index < 0 ? NSNotFound : index;
}

@end
