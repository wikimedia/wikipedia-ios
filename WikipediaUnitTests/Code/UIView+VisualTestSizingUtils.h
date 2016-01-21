//
//  UIView+VisualTestSizingUtils.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (VisualTestSizingUtils)

- (void)wmf_sizeToFitWindowWidth;

- (void)wmf_sizeToFitWidth:(CGFloat)width;

- (CGRect)wmf_sizeThatFitsWidth:(CGFloat)width;

@end
