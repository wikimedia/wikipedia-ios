//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#pragma once

#import <Foundation/Foundation.h>

#import "MWKSite.h"

@interface MWKTitle : NSObject <NSCopying>

/**
 * Initialize a new MWKTitle object from string input
 */
- (instancetype)initWithString:(NSString*)str site:(MWKSite*)site;

/**
 * Create a new MWKTitle object from string input
 */
+ (MWKTitle*)titleWithString:(NSString*)str site:(MWKSite*)site;

/**
 * Normalize a title string portion to text form
 */
+ (NSString*)normalize:(NSString*)str;

/**
 * The site this title belongs to
 */
@property (readonly, strong, nonatomic) MWKSite* site;

/**
 * Normalized title component only (decoded, no underscores)
 */
@property (readonly, copy, nonatomic) NSString* text;

/**
 * Fragment (component after the '#')
 * Warning: fragment may be nil!
 */
@property (readonly, copy, nonatomic) NSString* fragment;


/**
 * Full text-normalized namespace+title
 * Decoded, with spaces
 */
@property (readonly, copy, nonatomic) NSString* prefixedText;

/**
 * Full DB-normalized namespace+title
 * Decoded, with underscores
 */
@property (readonly, copy, nonatomic) NSString* prefixedDBKey;

/**
 * Full URL-normalized namespace+title
 * Encoded, with underscores
 */
@property (readonly, copy, nonatomic) NSString* prefixedURL;

/**
 * URL-normalized fragment, including the # if applicable
 * Always returns a string, may be empty string.
 */
@property (readonly, copy, nonatomic) NSString* fragmentForURL;

/**
 * Absolute URL to mobile view of this article
 */
@property (readonly, copy, nonatomic) NSURL* mobileURL;

/**
 * Absolute URL to desktop view of this article
 */
@property (readonly, copy, nonatomic) NSURL* desktopURL;

@end
