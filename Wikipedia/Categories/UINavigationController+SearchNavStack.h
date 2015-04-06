//  Created by Monte Hurd on 2/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UINavigationController (SearchNavStack)

- (id)searchNavStackForViewControllerOfClass:(Class)aClass;

- (id)getVCBeneathVC:(id)thisVC;

@end
