//
//  AnyPromise+WMFExtensions.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "AnyPromise+WMFExtensions.h"


@implementation AnyPromise (WMFExtensions)

- (AnyPromise*)wmf_ignoringErrors {
    return self.catch(^{ return nil; });
}

@end
