//  Created by Monte Hurd on 8/8/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NearbyResultCell.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "UIView+Debugging.h"
#import "WMF_Colors.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#define FONT [UIFont systemFontOfSize:17]
#define FONT_COLOR [UIColor blackColor]

#define DESCRIPTION_FONT [UIFont systemFontOfSize:14]
#define DESCRIPTION_FONT_COLOR [UIColor grayColor]
#define PADDING_ABOVE_DESCRIPTION 2.0f

@interface NearbyResultCell()

@property (weak, nonatomic) IBOutlet PaddedLabel *distanceLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *titleLabel;

@property (strong, nonatomic) NSDictionary *attributesTitle;
@property (strong, nonatomic) NSDictionary *attributesDescription;

@end

@implementation NearbyResultCell

-(void)setTitle: (NSString *)title
    description: (NSString *)description
{
    self.titleLabel.attributedText = [self getAttributedTitle: title
                                          wikiDataDescription: description];
}

-(NSAttributedString *)getAttributedTitle: (NSString *)title
                      wikiDataDescription: (NSString *)description
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:title];

    // Set base color and font of the entire result title.
    [str setAttributes: self.attributesTitle
                 range: NSMakeRange(0, str.length)];

    // Style and append the Wikidata description.
    if ((description.length > 0)) {
        NSMutableAttributedString *attributedDesc = [[NSMutableAttributedString alloc] initWithString:description];

        [attributedDesc setAttributes: self.attributesDescription
                                range: NSMakeRange(0, attributedDesc.length)];
        
        NSAttributedString *newline = [[NSMutableAttributedString alloc] initWithString:@"\n"];
        [str appendAttributedString:newline];
        [str appendAttributedString:attributedDesc];
    }

    return str;
}

-(void)setupStringAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = PADDING_ABOVE_DESCRIPTION;
    
    self.attributesDescription =
    @{
      NSFontAttributeName : DESCRIPTION_FONT,
      NSForegroundColorAttributeName : DESCRIPTION_FONT_COLOR,
      NSParagraphStyleAttributeName : paragraphStyle
      };
    
    self.attributesTitle =
    @{
      NSFontAttributeName : FONT,
      NSForegroundColorAttributeName : FONT_COLOR
      };
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.longPressRecognizer = nil;
        self.distance = nil;
        self.location = nil;
        self.deviceLocation = nil;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)awakeFromNib
{
    //[self randomlyColorSubviews];
    // self.distanceLabel.textColor = [UIColor whiteColor];
    self.distanceLabel.backgroundColor = WMF_COLOR_GREEN;
    self.distanceLabel.layer.cornerRadius = 2.0f;
    self.distanceLabel.padding = UIEdgeInsetsMake(0, 7, 0, 7);

    self.titleLabel.font = [UIFont systemFontOfSize:17.0 * MENUS_SCALE_MULTIPLIER];
    self.distanceLabel.font = [UIFont systemFontOfSize:13.0 * MENUS_SCALE_MULTIPLIER];

    [self adjustConstraintsScaleForViews:@[self.titleLabel, self.distanceLabel, self.thumbView]];
    
    [self setupStringAttributes];
}

-(void)setDistance:(NSNumber *)distance
{
    _distance = distance;
    
    self.distanceLabel.text = [self descriptionForDistance:distance];
}

-(NSString *)descriptionForDistance:(NSNumber *)distance
{
    // Make nearby use feet for meters according to locale.
    // stringWithFormat float decimal places: http://stackoverflow.com/a/6531587

    BOOL useMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];

    if (useMetric) {
    
        // Show in km if over 0.1 km.
        if (distance.floatValue > (999.0f / 10.0f)) {
            NSNumber *displayDistance = @(distance.floatValue / 1000.0f);
            NSString *distanceIntString = [NSString stringWithFormat:@"%.2f", displayDistance.floatValue];
            return [MWLocalizedString(@"nearby-distance-label-km", nil) stringByReplacingOccurrencesOfString: @"$1"
                                                                                                  withString: distanceIntString];
        // Show in meters if under 0.1 km.
        }else{
            NSString *distanceIntString = [NSString stringWithFormat:@"%d", distance.intValue];
            return [MWLocalizedString(@"nearby-distance-label-meters", nil) stringByReplacingOccurrencesOfString: @"$1"
                                                                                                      withString: distanceIntString];
        }
    }else{
        // Meters to feet.
        distance = @(distance.floatValue * 3.28084f);
        
        // Show in miles if over 0.1 miles.
        if (distance.floatValue > (5279.0f / 10.0f)) {
            NSNumber *displayDistance = @(distance.floatValue / 5280.0f);
            NSString *distanceIntString = [NSString stringWithFormat:@"%.2f", displayDistance.floatValue];
            return [MWLocalizedString(@"nearby-distance-label-miles", nil) stringByReplacingOccurrencesOfString: @"$1"
                                                                                                     withString: distanceIntString];
        // Show in feet if under 0.1 miles.
        }else{
            NSString *distanceIntString = [NSString stringWithFormat:@"%d", distance.intValue];
            return [MWLocalizedString(@"nearby-distance-label-feet", nil) stringByReplacingOccurrencesOfString: @"$1"
                                                                                                    withString: distanceIntString];
        }
    }
}

-(void)setLocation:(CLLocation *)location
{
    _location = location;
    
    [self applyRotationTransform];
}

-(void)setDeviceHeading:(CLHeading *)deviceHeading
{
    _deviceHeading = deviceHeading;

    [self applyRotationTransform];
}

-(double)headingBetweenLocation:(CLLocation *)l1 andLocation:(CLLocation *)l2
{
    // From: http://www.movable-type.co.uk/scripts/latlong.html
	double dy = l2.coordinate.longitude - l1.coordinate.longitude;
	double y = sin(dy) * cos(l2.coordinate.latitude);
	double x = cos(l1.coordinate.latitude) * sin(l2.coordinate.latitude) - sin(l1.coordinate.latitude) * cos(l2.coordinate.latitude) * cos(dy);
	return atan2(y, x);
}

-(void)applyRotationTransform
{
    self.thumbView.headingAvailable = self.headingAvailable;
    if(!self.headingAvailable) return;

    // Get angle between device and article coordinates.
    double angleRadians = [self headingBetweenLocation:self.deviceLocation andLocation:self.location];

    // Adjust for device rotation (deviceHeading is in degrees).
    double angleDegrees = RADIANS_TO_DEGREES(angleRadians);
    angleDegrees += 180;
    angleDegrees -= (self.deviceHeading.trueHeading - 180.0f);
    if (angleDegrees > 360) angleDegrees -= 360;
    if (angleDegrees < -360) angleDegrees += 360;

    /*
    if ([self.titleLabel.text isEqualToString:@"Museum of London"]){
        NSLog(@"angle = %f", angleDegrees);
    }
    */

    // Adjust for interface orientation.
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            angleDegrees += 90;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angleDegrees -= 90;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angleDegrees += 180;
            break;
        default: //UIInterfaceOrientationPortrait
            break;
    }

    /*
    if ([self.titleLabel.text isEqualToString:@"Museum of London"]){
        NSLog(@"angle = %f", angleDegrees);
    }
    */

    angleRadians = DEGREES_TO_RADIANS(angleDegrees);

    [self.thumbView drawTickAtHeading:angleRadians];    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
