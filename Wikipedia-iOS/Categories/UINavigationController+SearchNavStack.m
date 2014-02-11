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

@end
