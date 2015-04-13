//  Created by Monte Hurd on 4/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSURL+WMFRest.h"
#import "NSString+Extras.h"

@implementation NSURL (WMFRest)

-(BOOL)wmf_conformsToScheme:(NSString *)scheme andHasKey:(NSString *)key {
    return ([[self scheme] wmf_isEqualToStringIgnoringCase:scheme] && [[self host] wmf_isEqualToStringIgnoringCase:key]);
}

@end
