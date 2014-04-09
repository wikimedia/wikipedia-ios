//  Created by Monte Hurd on 1/15/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

// Category for showing alerts beneath the nav bar.

@interface UINavigationController (Alert)

// Shows alert text just beneath the nav bar.
// Fades out alert if alertText set to zero length string.
-(void)showAlert:(NSString *)alertText;

//TODO: maybe make showAlert immediately disappear if alertText nil... maybe not?

// Shows full screen alert html just beneath the nav bar.
// Any links open in Safari.
-(void)showHTMLAlert: (NSString *)html
         bannerImage: (UIImage *)bannerImage
         bannerColor: (UIColor *)bannerColor;

@end
