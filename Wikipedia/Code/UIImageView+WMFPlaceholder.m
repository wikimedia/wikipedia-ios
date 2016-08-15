//
//  UIImageView+WMFPlaceholder.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/10/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIImageView+WMFPlaceholder.h"
#import "UIImageView+WMFImageFetching.h"
#import "UIImage+WMFStyle.h"
#import "UIColor+WMFStyle.h"

@implementation UIImageView (WMFPlaceholder)

- (void)wmf_configureWithDefaultPlaceholder {
    [self wmf_reset];
    self.contentMode = UIViewContentModeCenter;
    self.backgroundColor = [UIColor wmf_placeholderImageBackgroundColor];
    self.tintColor = [UIColor wmf_placeholderImageTintColor];
    self.image = [UIImage wmf_placeholderImage];
}

@end
