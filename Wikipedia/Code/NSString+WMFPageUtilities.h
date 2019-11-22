@import Foundation;

/// Substring within a URL fragment that indicates whether or not it is a citation.
extern NSString *const WMFCitationFragmentSubstring;

@interface NSString (WMFPageUtilities)

/**
 * Determine if a fragment points to a reference.
 *
 * The receiver is usually obtained from the fragment of a link tapped by the user.
 *
 * @return `YES` if the receiver contains a substring indicating that it is a reference, otherwise `NO`.
 */
- (BOOL)wmf_isReferenceFragment;

/**
 * Determine if a fragment points to a citation.
 *
 * The receiver is usually obtained from the fragment of a link tapped by the user.
 *
 * @return `YES` if the receiver contains a substring indicating that it is a citation, otherwise `NO`.
 */
- (BOOL)wmf_isCitationFragment;

/**
 * Determine if a fragment points to an endnote.
 *
 * The receiver is usually obtained from the fragment of a link tapped by the user.
 *
 * @return `YES` if the receiver contains a substring indicating that it is an endnote, otherwise `NO`.
 */
- (BOOL)wmf_isEndNoteFragment;

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
