//
//  UIButton+FrameUtils.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/25/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (FrameUtils)

/// Set the receiver's size to fit the contents of the title label's intrinsic content size.
- (void)wmf_sizeToFitLabelContents;

@end
