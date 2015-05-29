//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "MWKSite.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKTitle : NSObject <NSCopying>

/// The site this title belongs to
@property (readonly, strong, nonatomic) MWKSite* site;

/// Normalized title component only (decoded, no underscores)
@property (readonly, copy, nonatomic) NSString* text;

/// Fragment passed in designated initializer.
@property (readonly, copy, nonatomic, nullable) NSString* fragment;

/// Percent-escaped fragment, prefixed with @c #, or an empty string if absent.
@property (readonly, copy, nonatomic) NSString* escapedFragment;

/// Absolute URL to mobile view of this article
@property (readonly, copy, nonatomic) NSURL* mobileURL;

/// Absolute URL to desktop view of this article
@property (readonly, copy, nonatomic) NSURL* desktopURL;

/**
 * Initializes a new title belonging to @c site with an optional fragment.
 *
 * The preferred initializer is @c initWithString:site:, which parses components in the string.
 *
 * @param site      The site to which this title belongs.
 * @param text      The text which makes up the title.
 * @param fragment  An optional fragment, e.g. @"#section".
 *
 * @return A new title.
 */
- (instancetype)initWithSite:(MWKSite*)site
             normalizedTitle:(NSString*)text
                    fragment:(NSString* __nullable)fragment NS_DESIGNATED_INITIALIZER;

/**
 * Initialize a new title from the given string, parsing & escaping the title and fragment.
 * @param string    A string which represents a title. For example:
 * @param site      The site which this title lives under.
 * @see MWKTitleTests
 */
- (instancetype)initWithString:(NSString*)string site:(MWKSite*)site;

/// Initialize a new title with `relativeInternalLink`, which is parsed after removing the `/wiki/` prefix.
- (instancetype)initWithInternalLink:(NSString*)relativeInternalLink site:(MWKSite*)site;

/// Convenience factory method wrapping `initWithString:site:`.
+ (MWKTitle*)titleWithString:(NSString*)str site:(MWKSite*)site;

- (BOOL)isEqualToTitle:(MWKTitle*)title;

///
/// @name Deprecated Properties
///

/// Full text-normalized namespace+title decoded, with spaces
/// @warning This method was added prematurely and never supported, so it's effectively an alias for `text`.
@property (readonly, copy, nonatomic) NSString* prefixedText __deprecated;

/// Full DB-normalized namespace+title
/// @see prefixedText
@property (readonly, copy, nonatomic) NSString* prefixedDBKey __deprecated;

/// Full URL-normalized namespace+title
/// @see prefixedText
@property (readonly, copy, nonatomic) NSString* prefixedURL __deprecated;

@end

NS_ASSUME_NONNULL_END
