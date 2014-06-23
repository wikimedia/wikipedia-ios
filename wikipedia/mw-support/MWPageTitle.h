//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface MWPageTitle : NSObject

/**
 * Initialize a new MWPageTitle object from string input
 */
-(id)initWithString:(NSString *)str;

/**
 * Create a new MWPageTitle object from string input
 */
+(MWPageTitle *)titleWithString:(NSString *)str;

/**
 * Normalize a title string portion to text form
 */
+(NSString *)normalize:(NSString *)str;


/**
 * Normalized namespace (decoded, no underscores)
 * Warning: not implemented yet
 */
@property (readonly) NSString *namespace;

/**
 * Normalized title component only (decoded, no underscores)
 */
@property (readonly) NSString *text;

/**
 * Fragment (component after the '#')
 * Warning: fragment may be nil!
 */
@property (readonly) NSString *fragment;


/**
 * Full text-normalized namespace+title
 * Decoded, with spaces
 */
@property (readonly) NSString *prefixedText;

/**
 * Full DB-normalized namespace+title
 * Decoded, with underscores
 */
@property (readonly) NSString *prefixedDBKey;

/**
 * Full URL-normalized namespace+title
 * Encoded, with underscores
 */
@property (readonly) NSString *prefixedURL;

/**
 * URL-normalized fragment, including the # if applicable
 * Always returns a string, may be empty string.
 */
@property (readonly) NSString *fragmentForURL;



@end
