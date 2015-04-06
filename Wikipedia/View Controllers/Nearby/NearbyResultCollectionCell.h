//  Created by Monte Hurd on 12/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "NearbyThumbnailView.h"

@class PaddedLabel, NearbyArrowView, NearbyThumbnailView;
@interface NearbyResultCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet NearbyThumbnailView* thumbView;

@property (strong, nonatomic) NSNumber* distance;
@property (nonatomic) BOOL headingAvailable;
@property (nonatomic) double angle;

@property (strong, nonatomic) UILongPressGestureRecognizer* longPressRecognizer;

- (void)setTitle:(NSString*)title
     description:(NSString*)description;

@end
