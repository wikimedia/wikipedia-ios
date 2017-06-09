@import Foundation;

/**
 * Protocol for shareable Wikipedia entities.
 */
@protocol WMFSharing <NSObject>

/// @return A plain text string which is a snippet of the article's text, or an empty string on failure.
- (NSString *)shareSnippet;

@end
