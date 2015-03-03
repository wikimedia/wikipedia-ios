//
//  ShareOptionsView.m
//  Wikipedia
//
//  Created by Adam Baso on 1/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFShareOptionsView.h"
#import "PaddedLabel.h"
#import "UIView+WMFRoundCorners.h"

static const int kCornerRadius = 4.2f;

@implementation WMFShareOptionsView

- (void)didMoveToSuperview {
    [self.cardImageViewContainer wmf_roundCorners:UIRectCornerTopLeft | UIRectCornerTopRight toRadius:kCornerRadius];
    [self.shareAsCardLabel wmf_roundCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight toRadius:kCornerRadius];
    self.shareAsTextLabel.layer.cornerRadius       = kCornerRadius;
    self.shareAsTextLabel.layer.masksToBounds      = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
}

@end
