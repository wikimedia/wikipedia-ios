//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSObject+WMFExtras.h"

@implementation NSObject (WMFExtras)

- (BOOL)isNull {
    return [self isKindOfClass:[NSNull class]];
}

- (BOOL)isDict {
    return [self isKindOfClass:[NSDictionary class]];
}

@end
