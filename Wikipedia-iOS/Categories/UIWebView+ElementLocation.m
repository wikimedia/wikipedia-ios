//  Created by Monte Hurd on 12/28/13.

#import "UIWebView+ElementLocation.h"

@implementation UIWebView (ElementLocation)

- (CGPoint)getScreenCoordsForHtmlImageWithSrc:(NSString *)src
{
    NSString *strToEval = [NSString stringWithFormat:@"getElementRectAsJson(getImageWithSrc('%@'));", src];
    NSString *jsonString = [self stringByEvaluatingJavaScriptFromString:strToEval];
    if (jsonString.length == 0) return CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) return CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    NSString *top = (NSString *)jsonDict[@"top"];
    NSString *left = (NSString *)jsonDict[@"left"];
    
    return CGPointMake(left.floatValue, top.floatValue);
}

- (CGPoint)getWebViewCoordsForHtmlImageWithSrc:(NSString *)src
{
    CGPoint p = [self getScreenCoordsForHtmlImageWithSrc:src];
    
    return CGPointMake(
        p.x + floor(self.scrollView.contentOffset.x),
        p.y + floor(self.scrollView.contentOffset.y)
    );
}

- (CGRect)getScreenRectForHtmlElementWithId:(NSString *)elementId
{
    NSString *strToEval = [NSString stringWithFormat:@"getElementRectAsJson(document.getElementById('%@'));", elementId];
    NSString *jsonString = [self stringByEvaluatingJavaScriptFromString:strToEval];
    if (jsonString.length == 0) return CGRectNull;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) return CGRectNull;
    NSString *top = (NSString *)jsonDict[@"top"];
    NSString *left = (NSString *)jsonDict[@"left"];
    NSString *width = (NSString *)jsonDict[@"width"];
    NSString *height = (NSString *)jsonDict[@"height"];
    
    return CGRectMake(left.floatValue, top.floatValue, width.floatValue, height.floatValue);
}

- (CGRect)getWebViewRectForHtmlElementWithId:(NSString *)elementId
{
    CGRect r = [self getScreenRectForHtmlElementWithId:elementId];
    CGPoint p = CGPointMake(
        r.origin.x + floor(self.scrollView.contentOffset.x),
        r.origin.y + floor(self.scrollView.contentOffset.y)
    );
    r.origin = p;
    return r;
}

@end
