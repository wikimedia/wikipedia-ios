@import UIKit;

@interface WMFCompassView : UIView

/**
 *  Compass bearing measured in radians, where 0 is North and pi is South.
 */
@property (nonatomic, assign) double angleRadians;

@property (nonatomic, copy) UIColor *lineColor;

@end
