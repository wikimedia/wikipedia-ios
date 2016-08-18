#import <UIKit/UIKit.h>

/**
 * Table cell with a custom minus button achieved by overlaying the default minus button with a custom minus button.
 */

@interface WMFCustomDeleteButtonTableViewCell : UITableViewCell

@property (strong, nonatomic, readonly) UIButton *deleteButton;

@end
