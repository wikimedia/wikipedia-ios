//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MediaWikiKit.h"
#import "NSString+WMFPageUtilities.h"
#import "Wikipedia-Swift.h"
#import "NSObjectUtilities.h"
#import "NSURL+WMFLinkParsing.h"
#import "NSString+WMFPageUtilities.h"
#import "NSString+WMFPageUtilities.h"
#import "NSURLComponents+WMFLinkParsing.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKTitle ()

@property (nonatomic, copy) NSURL* URL;
@property (readwrite, strong, nonatomic) MWKSite* deprecatedSite;
@property (readwrite, copy, nonatomic) NSString* deprecatedFragment;
@property (readwrite, copy, nonatomic) NSString* deprecatedText;

@property (readwrite, copy, nonatomic) NSString* prefixedDBKey;
@property (readwrite, copy, nonatomic) NSString* prefixedURL;
@property (readwrite, copy, nonatomic) NSString* escapedFragment;
@property (readwrite, copy, nonatomic) NSURL* mobileURL;
@property (readwrite, copy, nonatomic) NSURL* desktopURL;

@end

@implementation MWKTitle

- (instancetype)initWithURL:(NSURL* __nonnull)url {
    self = [super init];
    if (self) {
        self.URL = url;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        if (!self.URL && self.deprecatedSite && self.deprecatedText) {
            self.URL = [NSURL wmf_URLWithDomain:self.deprecatedSite.domain language:self.deprecatedSite.language title:self.deprecatedText fragment:self.deprecatedFragment];
        }
    }
    return self;
}

- (instancetype)initWithSite:(MWKSite*)site
             normalizedTitle:(NSString*)text
                    fragment:(NSString* __nullable)fragment {
    NSURLComponents* components = [NSURLComponents componentsWithURL:site.URL resolvingAgainstBaseURL:NO];
    components.wmf_title = text;
    components.wmf_fragment = fragment;
    return [self initWithURL:components.URL];
}

- (instancetype)initWithInternalLink:(NSString*)relativeInternalLink site:(MWKSite*)site {
    NSAssert(relativeInternalLink.length == 0 || [relativeInternalLink wmf_isInternalLink],
             @"Expected string with internal link prefix but got: %@", relativeInternalLink);
    return [self initWithString:[relativeInternalLink wmf_internalLinkPath] site:site];
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

#pragma mark - Computed Properties

- (NSString*)text {
    return self.URL.wmf_title;
}

- (NSString* __nullable)fragment {
    return self.URL.fragment;
}

- (MWKSite*)site {
    return [[MWKSite alloc] initWithURL:self.URL];
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
    return self.URL.wmf_mobileURL;
}

- (NSURL*)desktopURL {
    return self.URL.wmf_desktopURL;
}

- (BOOL)isNonStandardTitle {
    return self.URL.wmf_isNonStandardURL;
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


+ (NSUInteger)modelVersion {
    return 1;
}

- (id)decodeValueForKey:(NSString*)key withCoder:(NSCoder*)coder modelVersion:(NSUInteger)modelVersion {
    if (modelVersion == 0) {
        id value = [coder decodeObjectForKey:key];
        if ([key isEqualToString:@"text"]) {
            self.deprecatedText = value;
        }
        if ([key isEqualToString:@"fragment"]) {
            self.deprecatedFragment = value;
        }
        return value;
    } else {
        return [super decodeValueForKey:key withCoder:coder modelVersion:modelVersion];
    }
}

// Need to specify storage properties since text & site are readonly, which Mantle interprets as transitory.
+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString*)propertyKey {
#define IS_MWKTITLE_KEY(key) [propertyKey isEqualToString:WMF_SAFE_KEYPATH([MWKTitle new], key)]
    if (IS_MWKTITLE_KEY(URL)) {
        return MTLPropertyStoragePermanent;
    } else {
        // all other properties are computed from site and/or text
        return MTLPropertyStorageNone;
    }
}

@end

NS_ASSUME_NONNULL_END