//
//  WMFGradientView.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFGradientView.h"

@implementation WMFGradientView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (CAGradientLayer*)gradientLayer {
    return (CAGradientLayer*)self.layer;
}

@end
