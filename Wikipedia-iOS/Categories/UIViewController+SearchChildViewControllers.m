//  Created by Monte Hurd on 2/11/14.

#import "UIViewController+SearchChildViewControllers.h"

@implementation UIViewController (SearchChildViewControllers)

-(id)searchForChildViewControllerOfClass:(Class)aClass
{
    for (UIViewController *vc in self.childViewControllers) {
        if ([vc isMemberOfClass:aClass]) return vc;
    }
    return nil;
}

@end
