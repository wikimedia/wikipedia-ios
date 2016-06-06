//
//  NSURL+WMFLinkParsing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSURL+WMFLinkParsing.h"
#import "NSString+WMFExtras.h"
#import "NSString+WMFPageUtilities.h"
#import "NSURL+WMFExtras.h"
#import "NSURLComponents+WMFLinkParsing.h"

@interface NSURL (WMFLinkParsing_Private)

@property (nonatomic, readonly) NSInteger wmf_domainIndex;

@end

@implementation NSURL (WMFLinkParsing)

- (BOOL)wmf_isInternalLink {
    return [self.path wmf_isInternalLink];
}

- (BOOL)wmf_isCitation {
    return [self.fragment wmf_isCitationFragment];
}

- (NSString*)wmf_internalLinkPath {
    return [self.path wmf_internalLinkPath];
}

- (NSString*)wmf_domain {
    return [self.host substringFromIndex:self.wmf_domainIndex];
}

- (NSString*)wmf_language {
    NSRange dotRange = [self.host rangeOfString:@"."];
    if (dotRange.length == 1 && dotRange.location < 4 && dotRange.location > 1) {
        return [self.host substringToIndex:dotRange.location];
    } else {
        return nil;
    }
}

- (NSString*)wmf_title {
    NSString* title = [[self.path wmf_internalLinkPath] wmf_unescapedNormalizedPageTitle];
    if (title == nil) {
        title = @"";
    }
    return title;
}

- (NSURL*)wmf_mobileURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:YES];
    return components.URL;
}

- (BOOL)wmf_isNonStandardURL {
    return self.wmf_language == nil;
}

+ (NSURL*)wmf_URLWithDomain:(NSString*)domain language:(NSString* __nullable)language {
    return [[NSURLComponents wmf_componentsWithDomain:domain language:language] URL];
}

@end

@implementation NSURL (WMFLinkParsing_Private)

+ (NSRegularExpression*)WMFURLParsingDomainIndexRegularExpression {
    static NSRegularExpression* WMFURLParsingDomainIndexRegularExpression = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError* regexError = nil;
        WMFURLParsingDomainIndexRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"^[^.]*(.m){0,1}[.]" options:NSRegularExpressionCaseInsensitive error:&regexError];
        if (regexError) {
            DDLogError(@"Error creating domain parsing regex: %@", regexError);
        }
    });
    return WMFURLParsingDomainIndexRegularExpression;
}

- (NSInteger)wmf_domainIndex {
    if (self.host == nil) {
        return 0;
    }

    NSTextCheckingResult* regexResult = [[NSURL WMFURLParsingDomainIndexRegularExpression] firstMatchInString:self.host options:NSMatchingAnchored range:NSMakeRange(0, self.host.length)];

    NSInteger index = 0;

    if (regexResult != nil) {
        index = regexResult.range.location + regexResult.range.length;
    }

    return index;
}

@end
