//  Created by Monte Hurd on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WMFExtras)

/**
 * Convenience for handling `nil` strings when creating a URL.
 *
 * `+[NSURL URLWithString:]` will throw if the input is `nil`, or return `nil`, but this will
 * return `nil`, simplifying code that deals with optional strings & URLs.
 */
+ (nullable instancetype)wmf_optionalURLWithString:(nullable NSString*)string;

- (BOOL)wmf_isEqualToIgnoringScheme:(NSURL*)url;

- (BOOL)wmf_isSchemeless;

- (NSString*)wmf_schemelessURLString;

- (NSString*)wmf_mimeTypeForExtension;

/// Prepend the receiver with the given scheme, unless one was already present in which case the receiver is returned.
- (instancetype)wmf_urlByPrependingSchemeIfSchemeless:(NSString*)scheme;

/**
 * Prepend the receiver with "https" if it doesn't already have a scheme.
 * @see wmf_urlByPrependingSchemeIfSchemeless
 */
- (instancetype)wmf_urlByPrependingSchemeIfSchemeless;

/**
 * Gets a value for a given url query key.
 *
 * @param key   The key to check. For example 'somekey' in the url above.
 *
 * @return      Value associated with the passed key parameter. For the url http://www.wikipedia.org?somekey=somevalue using the key 'somekey' would return the value 'somevalue'. Returns nil if no key found.
 **/
- (nullable NSString*)wmf_valueForQueryKey:(NSString*)key;

/**
 * Image proxy urls will have an "originalSrc" key.
 *
 * @return  Returns the original non-proxy src url. Returns nil if no 'originalSrc' value found.
 **/
- (nullable NSURL*)wmf_imageProxyOriginalSrcURL;

/**
 * Determine if url links to different spot on *same* page.
 */
- (BOOL)wmf_isIntraPageFragment;

@end

NS_ASSUME_NONNULL_END
