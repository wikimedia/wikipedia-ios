//  Created by Monte Hurd on 11/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIScreen+Extras.h"

@implementation UIScreen (Extras)

-(BOOL)isThreePointFiveInchScreen
{
    return (((int)self.bounds.size.height) == 480);
}

@end
