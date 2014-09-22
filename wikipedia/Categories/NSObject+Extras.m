//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSObject+Extras.h"

@implementation NSObject (Extras)

-(BOOL)isNull
{
    return [self isKindOfClass:[NSNull class]];
}

-(BOOL)isDict
{
    return [self isKindOfClass:[NSDictionary class]];
}

@end
