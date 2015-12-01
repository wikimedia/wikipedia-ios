//  Created by Monte Hurd on 5/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ShareMenuSavePageActivity.h"
#import "WikipediaAppUtils.h"

@implementation ShareMenuSavePageActivity

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryAction;
}

- (NSString*)activityType {
    return @"wikipedia.app.savearticle";
}

- (NSString*)activityTitle {
    return MWLocalizedString(@"share-menu-save-page", nil);
}

- (UIImage*)getIconImage {
    CGRect rect = CGRectMake(0, 0, 50, 50);

    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);

    // get the context for CoreGraphics
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [self drawStarInContext:ctx
         withNumberOfPoints:5
                     center:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
                innerRadius:8
                outerRadius:20
                  fillColor:[UIColor clearColor]
                strokeColor:[UIColor blackColor]
                strokeWidth:1.0];

    // make image out of bitmap context
    UIImage* retImage = UIGraphicsGetImageFromCurrentImageContext();

    // free the context
    UIGraphicsEndImageContext();

    return retImage;
}

// Star Drawing! From: http://stackoverflow.com/a/18456212/135557
- (void)drawStarInContext:(CGContextRef)context
       withNumberOfPoints:(NSInteger)points
                   center:(CGPoint)center
              innerRadius:(CGFloat)innerRadius
              outerRadius:(CGFloat)outerRadius
                fillColor:(UIColor*)fill
              strokeColor:(UIColor*)stroke
              strokeWidth:(CGFloat)strokeWidth {
    CGFloat arcPerPoint = 2.0f * M_PI / points;
    CGFloat theta       = M_PI / 2.0f;

    // Move to starting point (tip at 90 degrees on outside of star)
    CGPoint pt = CGPointMake(center.x - (outerRadius * cosf(theta)), center.y - (outerRadius * sinf(theta)));
    CGContextMoveToPoint(context, pt.x, pt.y);

    for (int i = 0; i < points; i = i + 1) {
        // Calculate next inner point (moving clockwise), accounting for crossing of 0 degrees
        theta = theta - (arcPerPoint / 2.0f);
        if (theta < 0.0f) {
            theta = theta + (2 * M_PI);
        }
        pt = CGPointMake(center.x - (innerRadius * cosf(theta)), center.y - (innerRadius * sinf(theta)));
        CGContextAddLineToPoint(context, pt.x, pt.y);

        // Calculate next outer point (moving clockwise), accounting for crossing of 0 degrees
        theta = theta - (arcPerPoint / 2.0f);
        if (theta < 0.0f) {
            theta = theta + (2 * M_PI);
        }
        pt = CGPointMake(center.x - (outerRadius * cosf(theta)), center.y - (outerRadius * sinf(theta)));
        CGContextAddLineToPoint(context, pt.x, pt.y);
    }
    CGContextClosePath(context);
    CGContextSetLineWidth(context, strokeWidth);
    [fill setFill];
    [stroke setStroke];
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (UIImage*)activityImage {
    UIImage* starImage = [self getIconImage];
    return starImage;
}

- (BOOL)canPerformWithActivityItems:(NSArray*)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray*)activityItems {
}

- (UIViewController*)activityViewController {
    return nil;
}

- (void)performActivity {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SavePage" object:self userInfo:nil];

    [self activityDidFinish:YES];
}

@end
