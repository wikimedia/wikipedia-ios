//
//  UIImageView+WMFContentOffset.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WMFContentOffset)

- (void)wmf_setContentOffsetToCenterFeature:(CIFeature* __nullable)feature fromImage:(UIImage*)image;

- (void)wmf_setContentOffsetToCenterRect:(CGRect)rect image:(UIImage*)image;

- (void)wmf_setContentOffset:(CGPoint)offset image:(UIImage*)image;

- (void)wmf_resetContentOffset;

@end

NS_ASSUME_NONNULL_END
