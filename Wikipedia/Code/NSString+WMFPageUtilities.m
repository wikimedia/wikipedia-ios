//
//  WMFPageUtilities.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSString+WMFPageUtilities.h"
#import "NSString+WMFExtras.h"
#import "WMFRangeUtils.h"

NSString *const WMFInternalLinkPathPrefix = @"/wiki/";

NSString *const WMFCitationFragmentSubstring = @"cite_note";

@implementation NSString (WMFPageUtilities)

- (BOOL)wmf_isWikiResource {
    return [self containsString:WMFInternalLinkPathPrefix];
}

- (BOOL)wmf_isCitationFragment {
    return [self containsString:WMFCitationFragmentSubstring];
}

- (NSString *)wmf_pathWithoutWikiPrefix {
    NSRange internalLinkRange = [self rangeOfString:WMFInternalLinkPathPrefix];
    NSString *path = internalLinkRange.location == NSNotFound ? self : [self wmf_safeSubstringFromIndex:WMFRangeGetMaxIndex(internalLinkRange)];
    return [path precomposedStringWithCanonicalMapping];
}

- (NSString *)wmf_unescapedNormalizedPageTitle {
    return [[self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] wmf_normalizedPageTitle];
}

- (NSString *)wmf_normalizedPageTitle {
    return [[self stringByReplacingOccurrencesOfString:@"_" withString:@" "] precomposedStringWithCanonicalMapping];
}

- (NSString *)wmf_denormalizedPageTitle {
    return [[self stringByReplacingOccurrencesOfString:@" " withString:@"_"] precomposedStringWithCanonicalMapping];
}

@end
