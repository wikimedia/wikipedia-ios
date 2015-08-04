//
//  UIColor+WMFStyle.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIColor+WMFStyle.h"

@implementation UIColor (WMFStyle)

+ (instancetype)wmf_logoBlue {
    return [self wmf_logoBlueWithAlpha:1.0];
}

+ (instancetype)wmf_logoBlueWithAlpha:(CGFloat)alpha {
    // measured from WMF logo using DigitalColorMeter
    return [UIColor colorWithRed:0.08203125 green:0.40625 blue:0.5859375 alpha:1.0f];
}

@end
