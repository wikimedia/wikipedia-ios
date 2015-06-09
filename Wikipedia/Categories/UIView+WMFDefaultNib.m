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
    UIView* view = [[[self wmf_classNib] instantiateWithOwner:nil options:nil] firstObject];
    NSAssert(view, @"Instantiating %@ from default nib returned nil!", self);
    NSAssert([view isMemberOfClass:self], @"Expected %@ to be instance of class %@", view, self);
    return view;
}

+ (UINib*)wmf_classNib {
    return [UINib nibWithNibName:[self wmf_nibName] bundle:nil];
}

@end
