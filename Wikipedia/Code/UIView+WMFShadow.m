//
//  UIView+WMFShadow.m
//
//
//  Created by Corey Floyd on 8/25/15.
//
//

#import "UIView+WMFShadow.h"

@implementation UIView (WMFShadow)

- (void)wmf_setupShadow {
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowRadius = 4.0;
    self.layer.shadowOffset = CGSizeZero;
}

@end
