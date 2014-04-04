//  Created by Monte Hurd on 4/2/14.

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
