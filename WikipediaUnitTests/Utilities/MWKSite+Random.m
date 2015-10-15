//
//  MWKSite+Random.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSite+Random.h"

#import <BlocksKit/BlocksKit.h>

@implementation MWKSite (Random)

+ (instancetype)random {
    NSArray<NSString*>* languageCodes = [NSLocale ISOLanguageCodes];
    NSUInteger randomIndex            = arc4random() % languageCodes.count;
    return [[MWKSite alloc] initWithDomain:WMFDefaultSiteDomain
                                  language:languageCodes[randomIndex]];
}

@end
