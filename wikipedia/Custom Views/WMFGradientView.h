//
//  WMFGradientView.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CAGradientLayer;
@interface WMFGradientView : UIView
@property (nonatomic, strong, readonly) CAGradientLayer* gradientLayer;
@end
