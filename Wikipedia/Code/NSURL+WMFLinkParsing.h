@import Foundation;
#import <WMF/NSURL+WMFLinkParsing.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFAPIPath;
extern NSString *const WMFEditPencil;

@interface NSURL (WMFLinkParsing)

/**
 * Initialize a new URL with the commons URL -commons.wikimedia.org.
 *
 * @return A main page URL for the commons.wikimedia.org.
 **/
+ (nullable NSURL *)wmf_wikimediaCommonsURL;

/**
 * Initialize a new URL with the default Site domain -wikipedia.org - and `language`.
 *
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for example: `en`.
 *
 * @return A new URL with the default domain and language.
 **/
+ (nullable NSURL *)wmf_URLWithDefaultSiteAndlanguage:(nullable NSString *)language;

/// @return A URL with the default domain and the language code returned by @c locale.
+ (nullable NSURL *)wmf_URLWithDefaultSiteAndLocale:(NSLocale *)locale;

/// @return A site with the default domain and the current locale's language code.
+ (nullable NSURL *)wmf_URLWithDefaultSiteAndCurrentLocale;

/**
 * Initialize a new URL with a Wikimedia `domain` and `language`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for example: `en`.
 *
 * @return A new URL with the given domain and language.
 **/
+ (nullable NSURL *)wmf_URLWithDomain:(NSString *)domain language:(nullable NSString *)language;

/**
 * Initialize a new URL with a Wikimedia `domain`, `language`, `title` and `fragment`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 * @param title         An optional Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 * @return A new URL with the given domain, language, title and fragment.
 **/
+ (nullable NSURL *)wmf_URLWithDomain:(NSString *)domain language:(nullable NSString *)language title:(nullable NSString *)title fragment:(nullable NSString *)fragment;

/**
 * Return a new URL constructed from the `siteURL`, replacing the `title` and `fragment` with the given values.
 *
 * @param siteURL       A Wikimedia site URL. For exmaple: `https://en.wikipedia.org`.
 * @param title         A Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 * @param query         An optional query string, for example `wprov=spi1&foo=bar`.
 *
 * @return A new URL constructed from the `siteURL`, replacing the `title` and `fragment` with the given values.
 **/
+ (nullable NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL title:(nullable NSString *)title fragment:(nullable NSString *)fragment query:(nullable NSString *)query;

/**
 * Return a new URL constructed from the `siteURL`, replacing the `path` with the `internalLink`.
 *
 * @param siteURL       A Wikimedia site URL. For exmaple: `https://en.wikipedia.org`.
 * @param internalLink  A Wikimedia internal link path. For exmaple: `/wiki/Main_Page#section`.
 *
 * @return A new URL constructed from the `siteURL`, replacing the `path` with the `internalLink`.
 **/
//WMF_TECH_DEBT_TODO(this method should be generecized to "path" and handle the presence of / wiki /)
+ (nullable NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL escapedDenormalizedInternalLink:(NSString *)internalLink;

/**
 * Return a new URL constructed from the `siteURL`, replacing the `path` with the internal link prefix and the `path`.
 *
 * @param siteURL                                       A Wikimedia site URL. For exmaple: `https://en.wikipedia.org`.
 * @param escapedDenormalizedTitleQueryAndFragment           A Wikimedia path and fragment. For exmaple: `/Main_Page?wprov=sfii1#section`.
 *
 * @return A new URL constructed from the `siteURL`, replacing the `path` with the internal link prefix and the `path`.
 **/
//WMF_TECH_DEBT_TODO(this method should be folded into the above method and should handle the presence of a #)
+ (nullable NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL escapedDenormalizedTitleQueryAndFragment:(NSString *)escapedDenormalizedTitleQueryAndFragment;

/**
 *  Return a URL for the mobile API Endpoint for the current URL
 *
 *  @return return value description
 */
+ (nullable NSURL *)wmf_mobileAPIURLForURL:(NSURL *)URL;

/**
 *  Return a URL for the desktop API Endpoint for the current URL
 *
 *  @return return value description
 */
+ (nullable NSURL *)wmf_desktopAPIURLForURL:(NSURL *)URL;

/**
 *  Return the mobile version of the given URL
 *  by adding a m. subdomian
 *
 *  @param url The URL
 *
 *  @return Mobile version of the URL
 */
+ (nullable NSURL *)wmf_mobileURLForURL:(NSURL *)url;

/**
 *  Return the desktop version of the given URL
 *  by removing a m. subdomian
 *
 *  @param url The URL
 *
 *  @return Mobile version of the URL
 */
+ (nullable NSURL *)wmf_desktopURLForURL:(NSURL *)url;

/**
 * Return a new URL similar to the URL you call this method on but replace the title.
 *
 * @param title         A Wikimedia title. For exmaple: `Main Page`.
 *
 * @return A new URL based on the URL you call this method on with the given title.
 **/
- (nullable NSURL *)wmf_URLWithTitle:(NSString *)title;

/**
 * Return a new URL similar to the URL you call this method on but replace the title and fragemnt.
 *
 * @param title         A Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 * @param query         An optional query string.
 *
 * @return A new URL based on the URL you call this method on with the given title and fragment.
 **/
- (nullable NSURL *)wmf_URLWithTitle:(NSString *)title fragment:(nullable NSString *)fragment query:(nullable NSString *)query;

/**
 * Return a new URL similar to the URL you call this method on but replace the fragemnt.
 *
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 * @return A new URL based on the URL you call this method on with the given fragment.
 **/
- (nullable NSURL *)wmf_URLWithFragment:(nullable NSString *)fragment;

/**
 * Return a new URL similar to the URL you call this method on but replace the path.
 *
 * @param path         A full path - for example `/w/api.php`
 *
 * @return A new URL based on the URL you call this method on with the given path.
 **/
- (nullable NSURL *)wmf_URLWithPath:(NSString *)path isMobile:(BOOL)isMobile;

#pragma mark - URL Components

/**
 *  Return a URL with just the domain, language, and mobile subdomain of the reciever.
 *  Everything but the path
 *
 *  @return The site URL
 */
@property (nonatomic, copy, readonly, nullable) NSURL *wmf_siteURL;

@property (nonatomic, copy, readonly, nullable) NSString *wmf_domain;

@property (nonatomic, copy, readonly, nullable) NSString *wmf_language;

@property (nonatomic, copy, readonly, nullable) NSString *wmf_pathWithoutWikiPrefix;

@property (nonatomic, copy, readonly, nullable) NSString *wmf_title;

@property (nonatomic, copy, readonly, nullable) NSString *wmf_titleWithUnderscores;

@property (nonatomic, copy, readonly, nullable) NSURL *wmf_canonicalURL; // canonical URL

@property (nonatomic, copy, readonly, nullable) NSString *wmf_databaseKey; // string suitable for using as a unique key for any wiki page

/**
 *  Returns @c wmf_languageVariantCode if non-nil and non-empty string, @c wmf_language otherwise
 */
@property (nonatomic, copy, readonly, nullable) NSString *wmf_contentLanguageCode;

#pragma mark - Introspection

/**
 *  Return YES if the receiver has "cite_note" in the path
 */
@property (nonatomic, readonly) BOOL wmf_isWikiCitation;

/**
 *  Return YES if the receiver should be peekable via 3d touch
 */
@property (nonatomic, readonly) BOOL wmf_isPeekable;

/**
 *  Return YES if the URL has a .m subdomain
 */
@property (nonatomic, readonly) BOOL wmf_isMobile;

/**
 *  Return YES if the URL does not have a language subdomain
 */
@property (nonatomic, readonly) BOOL wmf_isNonStandardURL;

#pragma mark - Associated Objects

/**
 *  Settable property for language variant code, defaults to nil
 *  Returns language variant code if present or nil if no code set
 */
@property (nonatomic, copy, nullable) NSString *wmf_languageVariantCode;

@end

/**
 * A number of places in the app need a unique in-memory key for a URL, typically an article URL:
 * - WMFDataStore maintains a temporary local NSCache of WMFArticle instances.
 * - ArticleSummary and reading list processing use a unique key for calcualting differences
 *
 * The value of wmf_databaseKey derived a URL does not take language variants into account.
 * This key combines the value of wmf_databaseKey and wmf_languageVariantCode to form a unique key.
 * This key should be used in instance of NSCache, as keys to dictionaries or other in-memory uses.
 *
 * For Core Data entities, the key and variant are maintained as separate properties.
 * The key value in database entities is the value of wmf_databaseKey.
*/
@interface WMFInMemoryURLKey : NSObject
- (instancetype)initWithDatabaseKey:(NSString *)databaseKey languageVariantCode:(nullable NSString *)languageVariantCode NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithURL:(NSURL *)url;
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)isEqualToInMemoryURLKey:(WMFInMemoryURLKey *)rhs;
@property (readonly, nonatomic, copy) NSString *databaseKey;
@property (readonly, nonatomic, copy, nullable) NSString *languageVariantCode;
@property (readonly, nonatomic, copy, nullable) NSURL *URL;
@property (readonly, nonatomic, copy) NSString *userInfoString; // A unique string for this database key + variant code pair suitable for incorporation in key strings.
@end

@interface NSURL (WMFInMemoryURLKeyExtensions)
@property (readonly, nonatomic, copy, nullable) WMFInMemoryURLKey *wmf_inMemoryKey;
@end

NS_ASSUME_NONNULL_END
