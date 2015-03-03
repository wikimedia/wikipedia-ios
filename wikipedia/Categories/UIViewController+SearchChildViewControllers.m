//  Created by Monte Hurd on 2/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+SearchChildViewControllers.h"

@implementation UIViewController (SearchChildViewControllers)

- (id)searchForChildViewControllerOfClass:(Class)aClass {
    for (UIViewController* vc in self.childViewControllers.copy) {
        if ([vc isMemberOfClass:aClass]) {
            return vc;
        }
    }
    return nil;
}

@end
