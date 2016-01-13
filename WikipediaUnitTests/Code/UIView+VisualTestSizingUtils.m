//
//  UIView+VisualTestSizingUtils.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/3/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIView+VisualTestSizingUtils.h"

static UIInterfaceOrientation const WMFDefaultTestOrientation = UIInterfaceOrientationPortrait;

@implementation UIView (VisualTestSizingUtils)

- (CGRect)wmf_sizeThatFitsScreenWidth {
    return [self wmf_sizeThatFitsScreenWidthForOrientation:WMFDefaultTestOrientation];
}

- (CGRect)wmf_sizeThatFitsScreenWidthForOrientation:(UIInterfaceOrientation)orientation {
    CGSize nativesScreenSize = [UIScreen mainScreen].nativeBounds.size;
    CGSize preHeightAdjustmentSize = (CGSize){
        .width  = UIInterfaceOrientationIsLandscape(orientation) ? nativesScreenSize.height : nativesScreenSize.width,
        .height = 0
    };

    CGSize sizeThatFitsWidth = [self systemLayoutSizeFittingSize:preHeightAdjustmentSize
                                   withHorizontalFittingPriority:UILayoutPriorityRequired
                                         verticalFittingPriority:UILayoutPriorityFittingSizeLevel];

    return (CGRect){
               .origin = CGPointZero,
               .size   = CGSizeMake(floor(sizeThatFitsWidth.width), floor(sizeThatFitsWidth.height))
    };
}

- (void)wmf_sizeToFitScreenWidth {
    [self wmf_sizeToFitScreenWidthForOrientation:WMFDefaultTestOrientation];
}

- (void)wmf_sizeToFitScreenWidthForOrientation:(UIInterfaceOrientation)orientation {
    self.frame = [self wmf_sizeThatFitsScreenWidthForOrientation:orientation];
}

@end

@interface UICollectionViewCell (VisualTestSizingUtils)

@end

@implementation UICollectionViewCell (VisualTestSizingUtils)

- (void)wmf_sizeToFitScreenWidthForOrientation:(UIInterfaceOrientation)orientation {
    [super wmf_sizeToFitScreenWidthForOrientation:orientation];
    self.contentView.frame = self.frame;
}

@end

@interface UITableViewCell (VisualTestSizingUtils)

@end

@implementation UITableViewCell (VisualTestSizingUtils)

- (void)wmf_sizeToFitScreenWidthForOrientation:(UIInterfaceOrientation)orientation {
    [super wmf_sizeToFitScreenWidthForOrientation:orientation];
    self.contentView.frame = self.frame;
}

@end
