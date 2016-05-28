//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MediaWikiKit.h"
#import "NSString+WMFPageUtilities.h"
#import "Wikipedia-Swift.h"
#import "NSObjectUtilities.h"
#import "NSURL+WMFLinkParsing.h"
#import "NSString+WMFPageUtilities.h"
#import "NSString+WMFPageUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKTitle ()

@property (readwrite, strong, nonatomic) MWKSite* site;
@property (readwrite, copy, nonatomic) NSString* fragment;
@property (readwrite, copy, nonatomic) NSString* text;
@property (readwrite, copy, nonatomic) NSString* prefixedDBKey;
@property (readwrite, copy, nonatomic) NSString* prefixedURL;
@property (readwrite, copy, nonatomic) NSString* escapedFragment;
@property (readwrite, copy, nonatomic) NSURL* mobileURL;
@property (readwrite, copy, nonatomic) NSURL* desktopURL;

@end

@implementation MWKTitle

- (instancetype)initWithSite:(MWKSite*)site
             normalizedTitle:(NSString*)text
                    fragment:(NSString* __nullable)fragment {
    NSParameterAssert(site);
    self = [super init];
    if (self) {
        self.site = site;
        // HAX: fall back to empty strings in case of nil text to handle API edge cases & prevent crashes
        self.text     = text.length ? text : @"";
        self.fragment = fragment;
    }
    return self;
}

- (instancetype)initWithInternalLink:(NSString*)relativeInternalLink site:(MWKSite*)site {
    NSAssert(relativeInternalLink.length == 0 || [relativeInternalLink wmf_isInternalLink],
             @"Expected string with internal link prefix but got: %@", relativeInternalLink);
    return [self initWithString:[relativeInternalLink wmf_internalLinkPath] site:site];
}

- (MWKTitle* __nullable)initWithURL:(NSURL* __nonnull)url {
    MWKSite* site = [[MWKSite alloc] initWithURL:url];
    if (!site) {
        return nil;
    }
    return [self initWithSite:site
              normalizedTitle:[[url wmf_internalLinkPath] wmf_unescapedNormalizedPageTitle]
                     fragment:url.fragment];
}

- (instancetype)initWithString:(NSString*)string site:(MWKSite*)site {
    NSAssert(![string wmf_isInternalLink],
             @"Didn't expect %@ to be an internal link. Use initWithInternalLink:site: instead.",
             string);
    if ([string wmf_isInternalLink]) {
        // recurse here after stripping internal link prefix
        return [self initWithInternalLink:string site:site];
    } else {
        NSArray* bits = [string componentsSeparatedByString:@"#"];
        return [self initWithSite:site
                  normalizedTitle:[[bits firstObject] wmf_unescapedNormalizedPageTitle]
                         fragment:[bits wmf_safeObjectAtIndex:1]];
    }
}

+ (MWKTitle*)titleWithString:(NSString*)str site:(MWKSite*)site {
    return [[MWKTitle alloc] initWithString:str site:site];
}

- (NSString*)dataBaseKey {
    return [self.text stringByReplacingOccurrencesOfString:@" " withString:@"_"];
}

- (NSString*)escapedURLText {
    return [[self.text wmf_denormalizedPageTitle] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)escapedFragment {
    if (self.fragment) {
        // @fixme we use some weird escaping system...?
        return [@"#" stringByAppendingString:[self.fragment stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    } else {
        return @"";
    }
}

- (NSURL*)mobileURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.m.%@%@%@",
                                 self.site.language,
                                 self.site.domain,
                                 WMFInternalLinkPathPrefix,
                                 self.escapedURLText]];
}

- (NSURL*)desktopURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.%@%@%@",
                                 self.site.language,
                                 self.site.domain,
                                 WMFInternalLinkPathPrefix,
                                 self.escapedURLText]];
}

- (BOOL)isNonStandardTitle {
    //TODO: this is the best test for now
    //We should formailze this
    //Really we shoud remove MWKTitle in favor NSURLComponenets
    return self.site.language == nil;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKTitle class]]) {
        return [self isEqualToTitle:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToTitle:(MWKTitle*)otherTitle {
    return WMF_IS_EQUAL_PROPERTIES(self, site, otherTitle)
           && WMF_EQUAL_PROPERTIES(self, text, isEqualToString:, otherTitle);
}

- (BOOL)isEqualToTitleIncludingFragment:(MWKTitle*)otherTitle {
    return WMF_IS_EQUAL_PROPERTIES(self, site, otherTitle)
           && WMF_EQUAL_PROPERTIES(self, text, isEqualToString:, otherTitle)
           && WMF_EQUAL_PROPERTIES(self, fragment, isEqualToString:, otherTitle);
}

- (NSUInteger)hash {
    return self.site.hash
           ^ flipBitsWithAdditionalRotation(self.text.hash, 1);
}

#pragma mark - MTLModel

// Need to specify storage properties since text & site are readonly, which Mantle interprets as transitory.
+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString*)propertyKey {
#define IS_MWKTITLE_KEY(key) [propertyKey isEqualToString : WMF_SAFE_KEYPATH([MWKTitle new], key)]
    if (IS_MWKTITLE_KEY(text) || IS_MWKTITLE_KEY(site) || IS_MWKTITLE_KEY(fragment)) {
        return MTLPropertyStoragePermanent;
    } else {
        // all other properties are computed from site and/or text
        return MTLPropertyStorageNone;
    }
}

@end

NS_ASSUME_NONNULL_END