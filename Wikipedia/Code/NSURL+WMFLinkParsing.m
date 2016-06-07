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

@interface NSURL (WMFLinkParsing_Private)

@property (nonatomic, readonly) NSInteger wmf_domainIndex;

@end

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

+ (NSURL*)wmf_URLWithSiteURL:(NSURL*)siteURL path:(NSString*)path {
    NSAssert(![path wmf_isInternalLink],
             @"Didn't expect %@ to be an internal link. Use initWithInternalLink:site: instead.",
             path);
    if ([path wmf_isInternalLink]) {
        // recurse here after stripping internal link prefix
        return [NSURL wmf_URLWithSiteURL:siteURL internalLink:path];
    } else {
        NSArray* bits = [path componentsSeparatedByString:@"#"];
        return [NSURL wmf_URLWithSiteURL:siteURL title:[[bits firstObject] wmf_unescapedNormalizedPageTitle] fragment:[bits wmf_safeObjectAtIndex:1]];
    }
}

+ (NSURL*)wmf_URLWithSiteURL:(NSURL*)siteURL internalLink:(NSString*)internalLink {
    NSAssert(internalLink.length == 0 || [internalLink wmf_isInternalLink],
             @"Expected string with internal link prefix but got: %@", internalLink);
    return [self wmf_URLWithSiteURL:siteURL path:[internalLink wmf_internalLinkPath]];
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
    return hostComponents.count > 1 && [hostComponents[1] isEqualToString:@"m"];
}

- (NSString*)wmf_internalLinkPath {
    return [self.path wmf_internalLinkPath];
}

- (NSString*)wmf_domain {
    return [self.host substringFromIndex:self.wmf_domainIndex];
}

- (NSString*)wmf_language {
    NSRange dotRange = [self.host rangeOfString:@"."];
    if (dotRange.location != NSNotFound && dotRange.location > 1) {
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
    NSURLComponents* components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    components.host = [NSURLComponents wmf_hostWithDomain:self.wmf_domain language:self.wmf_language isMobile:YES];
    NSURL* mobileURL = components.URL ? : self;
    return mobileURL;
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
