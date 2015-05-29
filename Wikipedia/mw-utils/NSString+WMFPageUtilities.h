//
//  NSString+WMFPageUtilities.h
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Expected prefix for links to pages from the wiki that the link's page belongs to.
extern NSString* const WMFInternalLinkPathPrefix;

@interface NSString (WMFPageUtilities)

/**
 * @return Whether a URL is an internal link.
 * @see WMFInternalLinkPrefix
 */
- (BOOL)wmf_isInternalLink;

/// Strips the internal link prefix from @c urlString, if present.
- (NSString*)wmf_internalLinkPath;

/// Normalizes page titles extracted from URLs, replacing percent escapes and underscores.
- (NSString*)wmf_normalizedPageTitle;

@end
