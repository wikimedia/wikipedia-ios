#import <UIKit/UIKit.h>

@interface WMFTableHeaderLabelView : UIView
@property (copy, nonatomic) NSString *text;
- (CGFloat)heightWithExpectedWidth:(CGFloat)width;
@end
