//
//  MWKSavedPageEntry+Random.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSavedPageEntry+Random.h"
#import "MWKTitle+Random.h"

@implementation MWKSavedPageEntry (Random)

+ (instancetype)random {
    return [[MWKSavedPageEntry alloc] initWithTitle:[MWKTitle random]];
}

@end
