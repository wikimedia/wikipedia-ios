//
//  NSUserDefaults+WMFReset.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSUserDefaults+WMFReset.h"

@implementation NSUserDefaults (WMFReset)

- (void)wmf_resetToDefaultValues {
    [self removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [self synchronize];
}

@end
