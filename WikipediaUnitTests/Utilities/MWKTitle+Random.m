//
//  MWKTitle+Random.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKTitle+Random.h"
#import "MWKSite+Random.h"

@implementation MWKTitle (Random)

+ (instancetype)random {
    return [self randomWithFragment:nil];
}

+ (instancetype)randomWithFragment:(NSString*)fragment {
    return
        [[MWKTitle alloc] initWithSite:[MWKSite random]
                       normalizedTitle:[[NSUUID UUID] UUIDString]
                              fragment:fragment ? : [@"#" stringByAppendingString:[[NSUUID UUID] UUIDString]]];
}

@end
