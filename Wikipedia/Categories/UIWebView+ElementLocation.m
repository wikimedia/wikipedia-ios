//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+ElementLocation.h"

@implementation UIWebView (ElementLocation)

- (CGPoint)getScreenCoordsForHtmlImageWithSrc:(NSString*)src {
    NSString* strToEval =
        [NSString stringWithFormat:@"window.elementLocation.getElementRectAsJson(window.elementLocation.getImageWithSrc('%@'));", src];
    NSString* jsonString = [self stringByEvaluatingJavaScriptFromString:strToEval];
    if (jsonString.length == 0) {
        return CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    }
    NSData* jsonData       = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error         = nil;
    NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        return CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    }
    NSString* top  = (NSString*)jsonDict[@"top"];
    NSString* left = (NSString*)jsonDict[@"left"];

    void (^ zeroOutNulls)(NSString**) = ^(NSString** str){
        if ([*str isMemberOfClass :[NSNull class]]) {
            *str = @"0";
        }
    };
    zeroOutNulls(&top);
    zeroOutNulls(&left);

    return CGPointMake(left.floatValue, top.floatValue);
}

- (CGPoint)getWebViewCoordsForHtmlImageWithSrc:(NSString*)src {
    CGPoint p = [self getScreenCoordsForHtmlImageWithSrc:src];

    return CGPointMake(
        p.x + floor(self.scrollView.contentOffset.x),
        p.y + floor(self.scrollView.contentOffset.y)
        );
}

- (CGRect)getScreenRectForHtmlElementWithId:(NSString*)elementId {
    NSString* strToEval =
        [NSString stringWithFormat:@"window.elementLocation.getElementRectAsJson(document.getElementById('%@'));", elementId];
    NSString* jsonString = [self stringByEvaluatingJavaScriptFromString:strToEval];
    if (jsonString.length == 0) {
        return CGRectNull;
    }
    NSData* jsonData              = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error                = nil;
    NSMutableDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        return CGRectNull;
    }

    NSString* top    = (NSString*)jsonDict[@"top"];
    NSString* left   = (NSString*)jsonDict[@"left"];
    NSString* width  = (NSString*)jsonDict[@"width"];
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

    return CGRectMake(left.floatValue, top.floatValue, width.floatValue, height.floatValue);
}

- (CGRect)getWebViewRectForHtmlElementWithId:(NSString*)elementId {
    CGRect r  = [self getScreenRectForHtmlElementWithId:elementId];
    CGPoint p = CGPointMake(
        r.origin.x + floor(self.scrollView.contentOffset.x),
        r.origin.y + floor(self.scrollView.contentOffset.y)
        );
    r.origin = p;
    return r;
}

- (NSInteger)getIndexOfTopOnScreenElementWithPrefix:(NSString*)prefix count:(NSUInteger)count {
    // Checks all html elements in the web view which have id's of format prefix string followed
    // by count index (if prefix is "things_" and count is 3 it will check "thing_0", "thing_1"
    // and "thing_2") to see if they are onscreen. Returns index of first one found to be so.
    NSString* strToEval =
        [NSString stringWithFormat:@"window.elementLocation.getIndexOfFirstOnScreenElementWithTopGreaterThanY('%@', %lu, %f);", prefix, (unsigned long)count, self.scrollView.contentOffset.y];
    NSString* result = [self stringByEvaluatingJavaScriptFromString:strToEval];
    return (result) ? result.integerValue : -1;
}

@end
