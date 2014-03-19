//  Created by Monte Hurd on 2/11/14.

#import "UINavigationController+SearchNavStack.h"

@implementation UINavigationController (SearchNavStack)

-(id)searchNavStackForViewControllerOfClass:(Class)aClass
{
    for (UIViewController *vc in self.viewControllers) {
        if ([vc isMemberOfClass:aClass]) return vc;
    }
    return nil;
}

-(id)getVCBeneathVC:(id)thisVC
{
    id vcBeneath = nil;
    for (id vc in self.viewControllers) {
        if (vc == thisVC) return vcBeneath;
        vcBeneath = vc;
    }
    return nil;
}

@end
