//  Created by Monte Hurd on 1/15/14.

#import <UIKit/UIKit.h>

// Category for showing alerts over *any* view controller's view.

@interface UIViewController (Alert)

// Shows alert text at top of view controller's view.
// Fades out alert if alertText set to zero length string.
-(void)showAlert:(NSString *)alertText;

//TODO: maybe make showAlert immediately disappear if alertText nil... maybe not?

// Shows full screen alert html over top of view controller's view.
// Any links open in Safari.
-(void)showHTMLAlert: (NSString *)html
         bannerImage: (UIImage *)bannerImage
         bannerColor: (UIColor *)bannerColor;

@end
