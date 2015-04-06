//  Created by Monte Hurd on 2/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UINavigationController+SearchNavStack.h"

@implementation UINavigationController (SearchNavStack)

- (id)searchNavStackForViewControllerOfClass:(Class)aClass {
    for (UIViewController* vc in self.viewControllers.copy) {
        if ([vc isMemberOfClass:aClass]) {
            return vc;
        }
    }
    return nil;
}

- (id)getVCBeneathVC:(id)thisVC {
    id vcBeneath = nil;
    for (id vc in self.viewControllers.copy) {
        if (vc == thisVC) {
            return vcBeneath;
        }
        vcBeneath = vc;
    }
    return nil;
}

@end
