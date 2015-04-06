//
//  UIView+WMFDefaultNib.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIView+WMFDefaultNib.h"

@implementation UIView (WMFDefaultNib)

+ (NSString*)wmf_nibName {
    return NSStringFromClass(self);
}

+ (instancetype)wmf_viewFromClassNib {
    return [[[NSBundle mainBundle] loadNibNamed:[self wmf_nibName] owner:nil options:nil] firstObject];
}

@end
