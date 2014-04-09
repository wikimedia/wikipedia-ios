//  Created by Monte Hurd on 4/2/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIView+SearchSubviews.h"

@implementation UIView (SearchSubviews)

-(id)getFirstSubviewOfClass:(Class)class
{
    for (id view in self.subviews) {
        if([view isMemberOfClass:class]){
            return view;
        }
    }
    return nil;
}

@end
