//
//  UILabel+WMFStyling.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/25/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UILabel+WMFStyling.h"
#import "UIFont+WMFStyle.h"

@implementation UILabel (WMFStyling)

- (void)wmf_applyMenuScaleMultiplier {
    self.font = [self.font wmf_copyWithSizeScaledByMenuMultiplier];
}

- (void)wmf_applyDropShadow {
    self.shadowColor = [UIColor blackColor];
    self.shadowOffset = CGSizeMake(0.0, 1.0);
    self.layer.shadowRadius = 0.5;
}

@end
