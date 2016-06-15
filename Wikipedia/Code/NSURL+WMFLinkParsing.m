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
#import "Wikipedia-Swift.h"

@implementation NSURL (WMFLinkParsing)

#pragma mark - Constructors

+ (NSURL*)wmf_URLWithDomain:(NSString*)domain language:(nullable NSString*)language {
    return [[NSURLComponents wmf_componentsWithDomain:domain language:language] URL];
}

+ (NSURL*)wmf_URLWithDomain:(NSString*)domain language:(nullable NSString*)language title:(NSString*)title fragment:(nullable NSString*)fragment {
    return [[NSURLComponents wmf_componentsWithDomain:domain language:language title:title fragment:fragment] URL];
}

+ (NSURL*)wmf_URLWithSiteURL:(NSURL*)siteURL title:(nullable NSString*)title fragment:(nullable NSString*)fragment {
    return [siteURL wmf_URLWithTitle:title fragment:fragment];
}

+ (NSRegularExpression *)invalidPercentEscapesRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *percentEscapesRegex;
    dispatch_once(&onceToken, ^{
        percentEscapesRegex = [NSRegularExpression regularExpressionWithPattern:@"%[^0-9A-F]|%[0-9A-F][^0-9A-F]" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    return percentEscapesRegex;
}

+ (NSURL*)wmf_URLWithSiteURL:(NSURL*)siteURL unescapedDenormalizedTitleAndFragment:(NSString*)path {
    NSAssert(![path wmf_isInternalLink],
             @"Didn't expect %@ to be an internal link. Use initWithInternalLink:site: instead.",
             path);
    if ([path wmf_isInternalLink]) {
        // recurse here after stripping internal link prefix
        return [NSURL wmf_URLWithSiteURL:siteURL unescapedDenormalizedInternalLink:path];
    } else {
        NSArray* bits = [path componentsSeparatedByString:@"#"];
        return [NSURL wmf_URLWithSiteURL:siteURL title:[[bits firstObject] wmf_normalizedPageTitle] fragment:[bits wmf_safeObjectAtIndex:1]];
    }
}

+ (NSURL*)wmf_URLWithSiteURL:(NSURL*)siteURL escapedDenormalizedTitleAndFragment:(NSString*)path {
    NSAssert(![path wmf_isInternalLink],
             @"Didn't expect %@ to be an internal link. Use initWithInternalLink:site: instead.",
             path);
    NSAssert([[NSURL invalidPercentEscapesRegex] matchesInString:path options:0 range:NSMakeRange(0, path.length)].count == 0, @"%@ should only have valid percent escapes", path);
    if ([path wmf_isInternalLink]) {
        // recurse here after stripping internal link prefix
        return [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedInternalLink:path];
    } else {
        NSArray* bits = [path componentsSeparatedByString:@"#"];
        return [NSURL wmf_URLWithSiteURL:siteURL title:[[bits firstObject] wmf_unescapedNormalizedPageTitle] fragment:[bits wmf_safeObjectAtIndex:1]];
    }
}

+ (NSURL*)wmf_URLWithSiteURL:(NSURL*)siteURL unescapedDenormalizedInternalLink:(NSString*)internalLink {
    NSAssert(internalLink.length == 0 || [internalLink wmf_isInternalLink],
             @"Expected string with internal link prefix but got: %@", internalLink);
    return [self wmf_URLWithSiteURL:siteURL unescapedDenormalizedTitleAndFragment:[internalLink wmf_internalLinkPath]];
}


+ (NSURL*)wmf_URLWithSiteURL:(NSURL*)siteURL escapedDenormalizedInternalLink:(NSString*)internalLink {
    NSAssert(internalLink.length == 0 || [internalLink wmf_isInternalLink],
             @"Expected string with internal link prefix but got: %@", internalLink);
    return [self wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleAndFragment:[internalLink wmf_internalLinkPath]];
}

- (NSURL*)wmf_URLWithTitle:(NSString*)title {
    NSURLComponents* components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.wmf_title = title;
    return components.URL;
}

- (NSURL*)wmf_URLWithTitle:(NSString*)title fragment:(NSString*)fragment {
    NSURLComponents* components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.wmf_title    = title;
    components.wmf_fragment = fragment;
    return components.URL;
}

- (NSURL*)wmf_URLWithPath:(NSString*)path isMobile:(BOOL)isMobile {
    NSURLComponents* components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.path = path;
    if (isMobile != self.wmf_isMobile) {
        components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:isMobile];
    }
    return components.URL;
}

#pragma mark - Properties

- (BOOL)wmf_isInternalLink {
    return [self.path wmf_isInternalLink];
}

- (BOOL)wmf_isCitation {
    return [self.fragment wmf_isCitationFragment];
}

- (BOOL)wmf_isMobile {
    NSArray* hostComponents = [self.host componentsSeparatedByString:@"."];
    if (hostComponents.count < 3) {
        return NO;
    } else {
        if ([hostComponents[0] isEqualToString:@"m"]) {
            return true;
        } else {
            return [hostComponents[1] isEqualToString:@"m"];
        }
    }
}

- (NSString*)wmf_internalLinkPath {
    return [self.path wmf_internalLinkPath];
}

- (NSString*)wmf_domain {
    NSArray* hostComponents = [self.host componentsSeparatedByString:@"."];
    if (hostComponents.count < 3) {
        return self.host;
    } else {
        NSInteger firstIndex = 1;
        if ([hostComponents[1] isEqualToString:@"m"]) {
            firstIndex = 2;
        }
        NSArray* subarray = [hostComponents subarrayWithRange:NSMakeRange(firstIndex, hostComponents.count - firstIndex)];
        return [subarray componentsJoinedByString:@"."];
    }
}

- (NSString*)wmf_language {
    NSArray* hostComponents = [self.host componentsSeparatedByString:@"."];
    if (hostComponents.count < 3) {
        return nil;
    } else {
        NSString* potentialLanguage = hostComponents[0];
        return [potentialLanguage isEqualToString:@"m"] ? nil : potentialLanguage;
    }
}

- (NSString*)wmf_title {
    NSString* title = [[self.path wmf_internalLinkPath] wmf_normalizedPageTitle];
    if (title == nil) {
        title = @"";
    }
    return title;
}

- (NSURL*)wmf_mobileURL {
    if (self.wmf_isMobile) {
        return self;
    } else {
        NSURLComponents* components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
        components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:YES];
        NSURL* mobileURL = components.URL ? : self;
        return mobileURL;
    }
}

- (NSURL*)wmf_desktopURL {
    NSURLComponents* components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:NO];
    NSURL* desktopURL = components.URL ? : self;
    return desktopURL;
}

- (BOOL)wmf_isNonStandardURL {
    return self.wmf_language == nil;
}

- (UIUserInterfaceLayoutDirection)wmf_layoutDirection {
    switch (CFLocaleGetLanguageCharacterDirection((__bridge CFStringRef)self.wmf_language)) {
        case kCFLocaleLanguageDirectionRightToLeft:
            return UIUserInterfaceLayoutDirectionRightToLeft;
        default:
            return UIUserInterfaceLayoutDirectionLeftToRight;
    }
}

- (NSTextAlignment)wmf_textAlignment {
    switch (self.wmf_layoutDirection) {
        case UIUserInterfaceLayoutDirectionRightToLeft:
            return NSTextAlignmentRight;
        case UIUserInterfaceLayoutDirectionLeftToRight:
            return NSTextAlignmentLeft;
    }
}

@end