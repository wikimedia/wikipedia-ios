//
//  UIImageView+WMFContentOffset.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (WMFContentOffset)

- (void)wmf_setContentOffsetToCenterFeature:(CIFeature* __nullable)feature;

- (void)wmf_setContentOffsetToCenterRect:(CGRect)rect;

- (void)wmf_setContentOffset:(CGPoint)offset;

- (void)wmf_resetContentOffset;

@end
