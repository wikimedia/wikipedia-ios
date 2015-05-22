//  Created by Monte Hurd on 4/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSURL+WMFRest.h"
#import "NSString+Extras.h"

@implementation NSURL (WMFRest)

- (BOOL)wmf_conformsToScheme:(NSString*)scheme andHasHost:(NSString*)host {
    return ([[self scheme] wmf_isEqualToStringIgnoringCase:scheme] && [[self host] wmf_isEqualToStringIgnoringCase:host]);
}

- (BOOL)wmf_conformsToAnyOfSchemes:(NSArray*)schemes andHasHost:(NSString*)host {
    BOOL hostDoesConform = [[self host] wmf_isEqualToStringIgnoringCase:host];
    if (!hostDoesConform) {
        return NO;
    }
    for (NSString* scheme in schemes) {
        if ([[self scheme] wmf_isEqualToStringIgnoringCase:scheme]) {
            return YES;
        }
    }
    return NO;
}

- (NSString*)wmf_getValue {
    NSAssert(self.path.length > 1, @"wikipedia URLs must have a path: %@", self);
    if (self.path.length > 1) {
        return [self.path substringFromIndex:1];
    } else {
        return nil;
    }
}

@end
