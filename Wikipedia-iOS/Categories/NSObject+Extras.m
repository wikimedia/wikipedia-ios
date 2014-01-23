//  Created by Monte Hurd on 1/23/14.

#import "NSObject+Extras.h"

@implementation NSObject (Extras)

-(BOOL)isNull
{
    return [self isKindOfClass:[NSNull class]];
}

@end
