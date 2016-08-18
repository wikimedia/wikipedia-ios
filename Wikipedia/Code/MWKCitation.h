#import "MTLModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Individual citation (aka reference), parsed from a page's reflist HTML.
 */
@interface MWKCitation : MTLModel

/**
 * Identifier for the citation element in the reference list.
 */
@property (nonatomic, copy, readonly) NSString *citationIdentifier;

/**
 *  HTML representation of the receiver, as parsed from the reference list.
 */
@property (nonatomic, copy, readonly) NSString *rawHTML;

/**
 *  Lazily computed property containing "id" attributes of backlinks from the receiver.
 *
 *  Used to allow users to jump back to one of the locations where the receiver was cited.
 */
@property (nonatomic, copy, readonly) NSArray *backlinkIdentifiers;

/**
 *  Lazily computed property which returns the HTML inside the citation element, excluding the back-links.
 *
 *  This can be anything from a simple span of text with a link, but could also be a list of links.
 *
 *  @see rawHTML
 */
@property (nonatomic, copy, readonly) NSString *citationHTML;

- (MWKCitation *__nullable)initWithCitationIdentifier:(NSString *)citationIdentifier
                                              rawHTML:(NSString *)rawHTML;

- (MWKCitation *__nullable)initWithCitationIdentifier:(NSString *)citationIdentifier
                                              rawHTML:(NSString *)rawHTML
                                                error:(out NSError *__autoreleasing *__nullable)error;

@end

NS_ASSUME_NONNULL_END
