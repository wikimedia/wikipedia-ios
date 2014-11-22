//  Created by Monte Hurd on 4/17/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryLabel.h"
#import "Defines.h"

@implementation PageHistoryLabel

-(void)didMoveToSuperview
{
    self.font = [UIFont systemFontOfSize:12.0f * MENUS_SCALE_MULTIPLIER];
}

@end
