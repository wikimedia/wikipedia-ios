//
//  UIView+VisualTestSizingUtils.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScreen (WMFWidthForOrientation)

- (CGFloat)wmf_widthForOrientation:(UIInterfaceOrientation)orientation;

@end

@interface UIView (VisualTestSizingUtils)

- (void)wmf_sizeToFitScreenWidth;

- (void)wmf_sizeToFitScreenWidthForOrientation:(UIInterfaceOrientation)orientation;

- (CGRect)wmf_sizeThatFitsScreenWidth;

- (CGRect)wmf_sizeThatFitsScreenWidthForOrientation:(UIInterfaceOrientation)orientation;

@end
