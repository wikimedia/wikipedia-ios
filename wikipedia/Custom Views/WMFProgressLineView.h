
#import <UIKit/UIKit.h>

@interface WMFProgressLineView : UIView


/**
 *  Set the color of the progress.
 *  Default = [UIColor colorWithRed:0.106 green:0.678 blue:0.533 alpha:1]
 *  (Default Background Color = [UIColor colorWithRed:0.071 green:0.514 blue:0.404 alpha:1])
 */
@property (nonatomic, strong) UIColor* progressColor;

/**
 *  The current progress shown by the receiver.
 *  The progress value ranges from 0 to 1. The default value is 0.
 */
@property (nonatomic, assign) float progress;

- (void)setProgress:(float)progress animated:(BOOL)animated;

- (void)setProgress:(float)progress animated:(BOOL)animated completion:(dispatch_block_t)completion;

@end
