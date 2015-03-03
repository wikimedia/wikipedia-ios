#import <UIKit/UIKit.h>
#import "WMFDebugFeature.h"

@interface WMFDebugViewController : UITableViewController
{
    // declare ivar publicly so it can be set in other initializers
    NSArray* _features;
}
@property (nonatomic, readonly) NSArray* features;
@property (weak, nonatomic) id truePresentingVC;

/**
 * Designated initializer, for use in convenience initializers and testing.
 * @see WMFDebugViewController+EnabledFeatures
 */
- (instancetype)initWithFeatures:(NSArray*)features;

@end
