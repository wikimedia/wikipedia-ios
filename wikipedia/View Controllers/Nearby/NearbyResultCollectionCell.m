//  Created by Monte Hurd on 12/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NearbyResultCollectionCell.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "WMF_Colors.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"
#import "UIView+Debugging.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0f / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0f * M_PI)

#define TITLE_FONT [UIFont systemFontOfSize:(17.0f * MENUS_SCALE_MULTIPLIER)]
#define TITLE_FONT_COLOR [UIColor blackColor]

#define DISTANCE_FONT [UIFont systemFontOfSize:(13.0f * MENUS_SCALE_MULTIPLIER)]
#define DISTANCE_FONT_COLOR [UIColor whiteColor]
#define DISTANCE_BACKGROUND_COLOR WMF_COLOR_GREEN
#define DISTANCE_CORNER_RADIUS (2.0f * MENUS_SCALE_MULTIPLIER)
#define DISTANCE_PADDING UIEdgeInsetsMake(0.0f, 7.0f, 0.0f, 7.0f)

#define DESCRIPTION_FONT [UIFont systemFontOfSize:(14.0f * MENUS_SCALE_MULTIPLIER)]
#define DESCRIPTION_FONT_COLOR [UIColor grayColor]
#define DESCRIPTION_TOP_PADDING (2.0f * MENUS_SCALE_MULTIPLIER)

@interface NearbyResultCollectionCell()

@property (weak, nonatomic) IBOutlet PaddedLabel *distanceLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *titleLabel;

@property (strong, nonatomic) NSDictionary *attributesTitle;
@property (strong, nonatomic) NSDictionary *attributesDescription;

@end

@implementation NearbyResultCollectionCell

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
    paragraphStyle.paragraphSpacingBefore = DESCRIPTION_TOP_PADDING;
    
    self.attributesDescription =
    @{
      NSFontAttributeName : DESCRIPTION_FONT,
      NSForegroundColorAttributeName : DESCRIPTION_FONT_COLOR,
      NSParagraphStyleAttributeName : paragraphStyle
      };
    
    self.attributesTitle =
    @{
      NSFontAttributeName : TITLE_FONT,
      NSForegroundColorAttributeName : TITLE_FONT_COLOR
      };
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.longPressRecognizer = nil;
        self.distance = nil;
        self.location = CLLocationCoordinate2DMake(0, 0);
        self.deviceLocation = CLLocationCoordinate2DMake(0, 0);
    }
    return self;
}

- (void)awakeFromNib
{
    self.distanceLabel.textColor = DISTANCE_FONT_COLOR;
    self.distanceLabel.backgroundColor = DISTANCE_BACKGROUND_COLOR;
    self.distanceLabel.layer.cornerRadius = DISTANCE_CORNER_RADIUS;
    self.distanceLabel.padding = DISTANCE_PADDING;
    self.distanceLabel.font = DISTANCE_FONT;

    [self adjustConstraintsScaleForViews:@[self.titleLabel, self.distanceLabel, self.thumbView]];
    
    [self setupStringAttributes];

    //[self randomlyColorSubviews];
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

-(void)setLocation:(CLLocationCoordinate2D)location
{
    _location = location;
    
    [self applyRotationTransform];
}

-(void)setDeviceHeading:(CLLocationDirection)deviceHeading
{
    _deviceHeading = deviceHeading;

    [self applyRotationTransform];
}

-(double)headingBetweenLocation: (CLLocationCoordinate2D)loc1
                    andLocation: (CLLocationCoordinate2D)loc2
{
    // From: http://www.movable-type.co.uk/scripts/latlong.html
	double dy = loc2.longitude - loc1.longitude;
	double y = sin(dy) * cos(loc2.latitude);
	double x = cos(loc1.latitude) * sin(loc2.latitude) - sin(loc1.latitude) * cos(loc2.latitude) * cos(dy);
	return atan2(y, x);
}

-(double)getAngleFromLocation: (CLLocationCoordinate2D)fromLocation
                   toLocation: (CLLocationCoordinate2D)toLocation
             adjustForHeading: (CLLocationDirection)deviceHeading
         adjustForOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    // Get angle between device and article coordinates.
    double angleRadians = [self headingBetweenLocation:fromLocation andLocation:toLocation];

    // Adjust for device rotation (deviceHeading is in degrees).
    double angleDegrees = RADIANS_TO_DEGREES(angleRadians);
    angleDegrees -= deviceHeading;
    if (angleDegrees > 360.0) angleDegrees -= 360.0;
    if (angleDegrees < -360.0) angleDegrees += 360.0;

    /*
    if ([self.titleLabel.text isEqualToString:@"Museum of London"]){
        NSLog(@"angle = %f", angleDegrees);
    }
    */

    // Adjust for interface orientation.
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            angleDegrees += 90.0;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angleDegrees -= 90.0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angleDegrees += 180.0;
            break;
        default: //UIInterfaceOrientationPortrait
            break;
    }

    /*
    if ([self.titleLabel.text isEqualToString:@"Museum of London"]){
        NSLog(@"angle = %f", angleDegrees);
    }
    */

    return DEGREES_TO_RADIANS(angleDegrees);
}

-(void)applyRotationTransform
{
    self.thumbView.headingAvailable = self.headingAvailable;
    if(!self.headingAvailable) return;

    double angle =
        [self getAngleFromLocation: self.deviceLocation
                        toLocation: self.location
                  adjustForHeading: self.deviceHeading
              adjustForOrientation: self.interfaceOrientation];

    [self.thumbView drawTickAtHeading:angle];
}

/*
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
*/

@end
