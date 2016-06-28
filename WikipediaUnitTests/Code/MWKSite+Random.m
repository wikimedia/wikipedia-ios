//
//  MWKSite+Random.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSite+Random.h"

#import <BlocksKit/BlocksKit.h>

@implementation NSURL (WMFRandom)

+ (instancetype)wmf_randomSiteURL {
    NSArray<NSString*>* languageCodes = [NSLocale ISOLanguageCodes];
    NSUInteger randomIndex            = arc4random() % languageCodes.count;
    return [NSURL wmf_URLWithLanguage:languageCodes[randomIndex]];
}

+ (instancetype)wmf_randomArticleURL {
    return [self wmf_randomArticleURLWithFragment:nil];
}

+ (instancetype)wmf_randomArticleURLWithFragment:(NSString*)fragment {
    return [[self wmf_randomSiteURL] wmf_URLWithTitle:[[NSUUID UUID] UUIDString] fragment:fragment ? : [@"#" stringByAppendingString:[[NSUUID UUID] UUIDString]]];
}

@end

