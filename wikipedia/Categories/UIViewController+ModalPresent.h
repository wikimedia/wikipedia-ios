//  Created by Monte Hurd on 5/28/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIViewController (ModalPresent)

// The "block" parameter is passed the view controller to be shown just before
// the transition to that same view controller is performed. This allows view
// controller parameters to be configured differently.

- (void)performModalSequeWithID:(NSString*)identifier
                transitionStyle:(UIModalTransitionStyle)style
                          block:(void (^)(id))block;

@end
