//  Created by Monte Hurd on 8/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "NearbyThumbnailView.h"

@class PaddedLabel, NearbyArrowView, NearbyThumbnailView;
@interface NearbyResultCell : UITableViewCell

@property (weak, nonatomic) IBOutlet NearbyThumbnailView *thumbView;

@property (strong, nonatomic) NSNumber *distance;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) CLLocation *deviceLocation;
@property (nonatomic) BOOL headingAvailable;
@property (strong, nonatomic) CLHeading *deviceHeading;
@property (nonatomic) UIInterfaceOrientation interfaceOrientation;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPressRecognizer;

-(void)setTitle: (NSString *)title
    description: (NSString *)description;

@end
