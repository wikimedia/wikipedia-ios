@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WMFExtras)

/**
 * Convenience for handling `nil` strings when creating a URL.
 *
 * `+[NSURL URLWithString:]` will throw if the input is `nil`, or return `nil`, but this will
 * return `nil`, simplifying code that deals with optional strings & URLs.
 */
+ (nullable instancetype)wmf_optionalURLWithString:(nullable NSString *)string;

- (BOOL)wmf_isEqualToIgnoringScheme:(NSURL *)url;

- (BOOL)wmf_isSchemeless;

- (nullable NSString *)wmf_schemelessURLString;

- (nullable NSURL *)wmf_schemelessURL;

- (NSString *)wmf_mimeTypeForExtension;

/// Prepend the receiver with the given scheme, unless one was already present in which case the receiver is returned.
- (instancetype)wmf_urlByPrependingSchemeIfSchemeless:(NSString *)scheme;

/**
 * Prepend the receiver with "https" if it doesn't already have a scheme.
 * @see wmf_urlByPrependingSchemeIfSchemeless
 */
- (instancetype)wmf_urlByPrependingSchemeIfSchemeless;

/**
 * Determine if url links to different spot on *same* page.
 */
- (BOOL)wmf_isIntraPageFragment;

@end

NS_ASSUME_NONNULL_END
