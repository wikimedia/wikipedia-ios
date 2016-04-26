#import <UIKit/UIKit.h>

/**
 * Table cell with a custom minus button achieved by overlaying the default minus button with a custom minus button.
 */

@interface WMFTableViewCellWithCustomMinusButton : UITableViewCell

@property (strong, nonatomic, readonly) UIButton* minusButton;

@end
