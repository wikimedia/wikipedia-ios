//
//  UIView+WMFShadow.h
//
//
//  Created by Corey Floyd on 8/25/15.
//
//

#import <UIKit/UIKit.h>

@interface UIView (WMFShadow)

/**
 *  Setup and draw a shadow
 */
- (void)wmf_setupShadow;

/**
 *  Update the shadow based on bounds changes
 *  Call this whenever the bounds of the view changes to update the shadow
 */
- (void)wmf_updateShadowPathBasedOnBounds;

@end
