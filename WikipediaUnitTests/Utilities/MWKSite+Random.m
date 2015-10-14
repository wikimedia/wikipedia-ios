//
//  MWKSite+Random.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSite+Random.h"

@implementation MWKSite (Random)

+ (instancetype)random {
    return [[NSSet setWithArray:[NSLocale availableLocaleIdentifiers]] anyObject];
}

@end
