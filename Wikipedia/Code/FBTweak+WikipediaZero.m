//
//  FBTweak+WikipediaZero.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/22/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "FBTweak+WikipediaZero.h"
#import <Tweaks/FBTweakInline.h>

static NSString *const WMFWikipediaZeroHeaderTweakIdentifier = @"org.wikimedia.wikipedia.tweaks.networking.zero.fakezeroheaders";

@implementation FBTweak (WikipediaZero)

+ (void)load {
    FBTweakCategory *networkingCategory = [[FBTweakStore sharedInstance] tweakCategoryWithName:@"Networking"];
    NSParameterAssert(networkingCategory);

    FBTweakCollection *zeroTweakCollection = [[FBTweakCollection alloc] initWithName:@"Wikipedia Zero"];
    [networkingCategory addTweakCollection:zeroTweakCollection];

    FBTweak *zeroHeaders = [[FBTweak alloc] initWithIdentifier:WMFWikipediaZeroHeaderTweakIdentifier];
    zeroHeaders.name = @"Mock Wikipedia Zero headers.";
    zeroHeaders.defaultValue = @NO;

    [zeroTweakCollection addTweak:zeroHeaders];
}

+ (BOOL)wmf_shouldMockWikipediaZeroHeaders {
    return [[[[[[FBTweakStore sharedInstance] tweakCategoryWithName:@"Networking"]
        tweakCollectionWithName:@"Wikipedia Zero"]
        tweakWithIdentifier:WMFWikipediaZeroHeaderTweakIdentifier] currentValue] boolValue];
}

@end
