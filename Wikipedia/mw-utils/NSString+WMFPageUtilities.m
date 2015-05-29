//
//  WMFPageUtilities.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSString+WMFPageUtilities.h"
#import "NSString+Extras.h"
#import "WMFRangeUtils.h"

NSString* const WMFInternalLinkPathPrefix = @"/wiki/";

@implementation NSString (WMFPageUtilities)

- (BOOL)wmf_isInternalLink {
    return [self rangeOfString:WMFInternalLinkPathPrefix].location != NSNotFound;
}

- (NSString*)wmf_internalLinkPath {
    NSRange internalLinkRange = [self rangeOfString:WMFInternalLinkPathPrefix];
    return internalLinkRange.location == NSNotFound ?
           self
           : [self wmf_safeSubstringFromIndex:WMFRangeGetMaxIndex(internalLinkRange)];
}

- (NSString*)wmf_normalizedPageTitle {
    return [[self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
            stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

@end
