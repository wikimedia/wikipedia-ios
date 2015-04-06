//  Created by Monte Hurd on 8/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface NearbyThumbnailView : UIView

- (void)setImage:(UIImage*)image isPlaceHolder:(BOOL)isPlaceholder;

@property (nonatomic) double angle;

@property (nonatomic) BOOL headingAvailable;

@end
