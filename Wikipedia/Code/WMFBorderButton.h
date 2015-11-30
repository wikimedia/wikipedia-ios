
#import <UIKit/UIKit.h>

@interface WMFBorderButton : UIButton

@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic, strong) UIColor* borderColor;

/**
 *  Create a bordered button
 *
 *  @param width  The width of the border
 *  @param radius The corner radius of the border
 *  @param color  The color of the border
 *
 *  @return A new bordered button
 */
+ (WMFBorderButton*)buttonWithBorderWidth:(CGFloat)width cornerRadius:(CGFloat)radius color:(UIColor*)color;

/**
 *  Returns a button with default options for width, color, radius
 *
 *  @return A new default configured Button
 */
+ (WMFBorderButton*)standardBorderButton;



@end
