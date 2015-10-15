//
//  MWKHistoryEntry+MWKRandom.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKHistoryEntry+MWKRandom.h"
#import "MWKTitle+Random.h"

MWKHistoryDiscoveryMethod MWKHistoryDiscoveryMethodMakeRandom() {
    return (MWKHistoryDiscoveryMethod)arc4random() % 7;
}

@implementation MWKHistoryEntry (MWKRandom)

+ (instancetype)random {
    return [[self alloc] initWithTitle:[MWKTitle random]
                       discoveryMethod :MWKHistoryDiscoveryMethodMakeRandom()];
}

+ (instancetype)randomSaveableEntry; {
    // HAX: discovery methods other than those defined below are _all_ considered unknown
    MWKHistoryDiscoveryMethod randomDiscoveryMethod;
    switch (arc4random() % 4) {
        case 1:
            randomDiscoveryMethod = MWKHistoryDiscoveryMethodLink;
            break;
        case 2:
            randomDiscoveryMethod = MWKHistoryDiscoveryMethodRandom;
            break;
        case 3:
            randomDiscoveryMethod = MWKHistoryDiscoveryMethodSearch;
            break;
        default:
            randomDiscoveryMethod = MWKHistoryDiscoveryMethodSaved;
            break;
    }
    MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithTitle:[MWKTitle random]
                                                    discoveryMethod :randomDiscoveryMethod];
    // HAX: history entries need significantly different dates for the order to persist properly
    float timeInterval = roundf((float)1e6 * ((float)arc4random() / (float)UINT32_MAX));
    // HAX: round-trip the date through formatting to prevent data loss (bug) and allow equality checks to pass
    entry.date = [entry getDateFromIso8601DateString:
                  [entry iso8601DateString:
                   [NSDate dateWithTimeIntervalSinceNow:timeInterval]]];
    return entry;
}

@end
