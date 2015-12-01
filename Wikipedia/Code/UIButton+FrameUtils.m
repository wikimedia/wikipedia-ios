//
//  UIButton+FrameUtils.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/25/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIButton+FrameUtils.h"
#import "UIView+WMFFrameUtils.h"

@implementation UIButton (FrameUtils)

- (void)wmf_sizeToFitLabelContents {
#if DEBUG
    if (!UIEdgeInsetsEqualToEdgeInsets(self.titleEdgeInsets, UIEdgeInsetsZero)) {
        NSLog(@"WARNING: non-zero edge insets on button label when trying to fit to label contents.");
    }
#endif
    [self wmf_setFrameSize:[self.titleLabel intrinsicContentSize]];
}

@end
