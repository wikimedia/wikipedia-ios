//  Created by Monte Hurd on 1/15/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

// Category for showing alerts from any view controller.

@interface UIViewController (Alert)

// Shows alert text just beneath the nav bar.
// Fades out alert if alertText set to zero length string.
-(void)showAlert:(NSString *)alertText;

-(void)fadeAlert;

-(void)hideAlert;

@end
