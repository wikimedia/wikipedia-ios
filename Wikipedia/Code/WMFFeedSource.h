
#import <Foundation/Foundation.h>

@protocol WMFFeedSource <NSObject>

//Start monitoring for updates
- (void)startUpdating;

//Stop monitoring for updates
- (void)stopUpdating;

/**
 *  Update now. If force is YES, you should violate any internal business rules and run your update logic immediately.
 *
 */
- (void)updateForce:(BOOL)force;

@end
