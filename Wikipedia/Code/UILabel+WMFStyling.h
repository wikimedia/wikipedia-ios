//
//  UILabel+WMFStyling.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/25/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (WMFStyling)

/// Scale the receiver's current font size by the `MENUS_SCALE_MULTIPLIER`.
- (void)wmf_applyMenuScaleMultiplier;

- (void)wmf_applyDropShadow;

@end
