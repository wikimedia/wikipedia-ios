//  Created by Monte Hurd on 1/15/14.

#import <UIKit/UIKit.h>

@interface UIViewController (Alert)

// Category for showing an some alert text at top of *any* view controller's
// view.

// Shows alert. Fades out alert if alertText set to zero length string.
-(void)showAlert:(NSString *)alertText;

//TODO: make showAlert immediately disappear if alertText nil.

@end
