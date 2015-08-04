//  Created by Monte Hurd on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (Extras)

/**
 * Convenience for handling `nil` strings when creating a URL.
 *
 * `+[NSURL URLWithString:]` will throw if the input is `nil`, or return `nil`, but this will
 * return `nil`, simplifying code that deals with optional strings & URLs.
 */
+ (nullable instancetype)wmf_optionalURLWithString:(nullable NSString*)string;

- (BOOL)wmf_isEqualToIgnoringScheme:(NSURL*)url;

- (NSString*)wmf_schemelessURLString;

- (NSString*)wmf_mimeTypeForExtension;

/// Prepend the receiver with the given scheme, unless one was already present in which case the receiver is returned.
- (instancetype)wmf_urlByPrependingSchemeIfSchemeless:(NSString*)scheme;

/**
 * Prepend the receiver with "https" if it doesn't already have a scheme.
 * @see wmf_urlByPrependingSchemeIfSchemeless
 */
- (instancetype)wmf_urlByPrependingSchemeIfSchemeless;

- (id)wmf_valueForQueryKey:(NSString*)queryKey;

@end

NS_ASSUME_NONNULL_END
