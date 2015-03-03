//  Created by Monte Hurd on 6/26/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+ModalsSearch.h"
#import "ModalMenuAndContentViewController.h"

@implementation UIViewController (SearchModalsAndNavStack)

- (id)searchModalsForViewControllerOfClass:(Class)aClass;
{
    id vc = self;
    while (vc) {
        if ([vc isMemberOfClass:aClass]) {
            return vc;
        }
        SEL selector = @selector(truePresentingVC);
        if ([vc respondsToSelector:selector]) {
            IMP imp = [vc methodForSelector:selector];
            id (* func)(id, SEL) = (void*)imp;
            vc = func(vc, selector);
        } else {
            break;
        }
    }
    return nil;
}

@end
