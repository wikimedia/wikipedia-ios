//
//  WEWeakReference.m
//  WEPopover
//
//  Created by Werner Altewischer on 25/02/16.
//  Copyright © 2016 Werner IT Consultancy. All rights reserved.
//

#import "WEWeakReference.h"

@implementation WEWeakReference

+ (instancetype)weakReferenceWithObject:(id)object {
    WEWeakReference *ref = [self new];
    ref.object = object;
    return ref;
}

@end
