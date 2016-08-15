//
//  NSString+WMFPageUtilities.h
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Expected prefix for links to pages from the wiki that the link's page belongs to.
extern NSString *const WMFInternalLinkPathPrefix;

/// Substring within a URL fragment that indicates whether or not it is a citation.
extern NSString *const WMFCitationFragmentSubstring;

@interface NSString (WMFPageUtilities)

/**
 * Determine if a URL-like string is an internal link.
 *
 * The receiver can either be a relative or absolute URL, or the path component of a URL.
 *
 * @return `YES` if the receiver contains a substring indicating it is an internal-wiki link, otherwise `NO`.
 *
 * @see WMFInternalLinkPrefix
 */
- (BOOL)wmf_isWikiResource;

/**
 * Determine if a fragment points to a citation.
 *
 * The receiver is usually obtained from the fragment of a link tapped by the user.
 *
 * @return `YES` if the receiver contains a substring indicating that it is a citation, otherwise `NO`.
 */
- (BOOL)wmf_isCitationFragment;

/**
 * Strips the internal link prefix from the receiver, if present.
 *
 * @warning If you need to be sure any query or fragment are also stripped, use this same category on `NSURL`.
 */
- (NSString *)wmf_pathWithoutWikiPrefix;

/**
 *  @return Copy of the receiver after normalizing page titles extracted from URLs, replacing percent escapes
 *          and underscores.
 */
- (NSString *)wmf_unescapedNormalizedPageTitle;

/**
 *  @return The receiver, but with underscores replaced with spaces.
 *
 *  @see wmf_denormalizedPageTitle
 */
- (NSString *)wmf_normalizedPageTitle;

/**
 *  Process a normalized title into one which can be used as an API request parameter.
 *
 *  @return The receiver, with spaces replaced by underscores.
 *
 *  @see wmf_normalizedPageTitle
 */
- (NSString *)wmf_denormalizedPageTitle;

@end
