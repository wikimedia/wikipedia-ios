//  Created by Monte Hurd on 11/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIScreen+Extras.h"

@implementation UIScreen (Extras)

- (BOOL)isThreePointFiveInchScreen {
    CGFloat scalar =
        (UIInterfaceOrientationIsPortrait([self interfaceOrientation]))
        ?
        self.screenSize.height
        :
        self.screenSize.width;
    return (((int)scalar) == 480);
}

// UIViewController's interfaceOrientation property is deprecated.
// The status bar's orientation isn't (as of iOS 8).
- (UIInterfaceOrientation)interfaceOrientation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}

// iOS 8 style orientation dependent screen size. From: http://stackoverflow.com/a/25088478/135557
- (CGSize)screenSize {
    CGSize screenSize = self.bounds.size;
    if (
        (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1)
        &&
        UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
        ) {
        return CGSizeMake(screenSize.height, screenSize.width);
    }
    return screenSize;
}

@end
