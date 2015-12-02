//
//  MWKSite+CommonsSite.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSite+CommonsSite.h"

@implementation MWKSite (CommonsSite)

+ (instancetype)wikimediaCommons {
    return [[self alloc] initWithDomain:@"wikimedia.org" language:@"commons"];
}

@end
