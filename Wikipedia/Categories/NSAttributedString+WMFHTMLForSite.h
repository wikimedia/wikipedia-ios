//
//  NSAttributedString+WMFHTMLForSite.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/28/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWKSite;

@interface NSAttributedString (WMFHTMLForSite)

/**
 * Create an options dictionary which can be used to create an attributed string.
 *
 * @param site  The site which the base document URL will be derived from.
 *
 * @return A dictionary with the default options for creating attributed strings from Wikipedia HTML.
 */
+ (NSDictionary*)wmf_defaultHTMLOptionsForSite:(MWKSite*)site;

/**
 * Create an attributed string with HTML that targets the given `site`.
 *
 * @param data  The HTML data to construct an attributed string from.
 * @param site  The site which the base document URL will be derived from.
 *
 * @see +[NSAttributedString wmf_defaultOptionsForSite]
 */
- (instancetype)initWithHTMLData:(NSData*)data site:(MWKSite*)site;

@end
