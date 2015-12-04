//
//  NSDictionary+WMFCommonParams.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSDictionary+WMFCommonParams.h"
#import "WMFNumberOfExtractCharacters.h"
#import "UIScreen+WMFImageWidth.h"

@implementation NSDictionary (WMFCommonParams)

+ (instancetype)wmf_titlePreviewRequestParameters {
    return [self wmf_titlePreviewRequestParametersWithExtractLength:WMFNumberOfExtractCharacters];
}

+ (instancetype)wmf_titlePreviewRequestParametersWithExtractLength:(NSUInteger)length {
    return [[self alloc] initWithObjectsAndKeys:
            @"", @"continue",
            @"json", @"format",
            @"query", @"action",
            @"extracts|pageterms|pageimages", @"prop",
            // extracts
            @YES, @"exintro",
            @(length), @"exchars",
            @"", @"explaintext",
            // pageterms
            @"description", @"wbptterms",
            // pageimage
            @"thumbnail", @"piprop",
            [[UIScreen mainScreen] wmf_leadImageWidthForScale], @"pithumbsize", nil];
}

@end
