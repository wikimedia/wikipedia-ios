#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFDefaultSiteDomain;

@interface NSURL (WMFLinkParsing)

#pragma mark - URL Creation

/**
 * Initialize a new URL with the main page URL for a given language anf the default domain - wikipedia.org.
 *
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for example: `en`.
 *
 * @return A main page URL for the given language.
 **/
+ (nullable NSURL *)wmf_mainPageURLForLanguage:(NSString *)language;

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
+ (NSURL *)wmf_URLWithDefaultSiteAndlanguage:(nullable NSString *)language;

/// @return A URL with the default domain and the language code returned by @c locale.
+ (NSURL *)wmf_URLWithDefaultSiteAndLocale:(NSLocale *)locale;

/// @return A site with the default domain and the current locale's language code.
+ (NSURL *)wmf_URLWithDefaultSiteAndCurrentLocale;

/**
 * Initialize a new URL with a Wikimedia `domain` and `language`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for example: `en`.
 *
 * @return A new URL with the given domain and language.
 **/
+ (NSURL *)wmf_URLWithDomain:(NSString *)domain language:(nullable NSString *)language;

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
+ (NSURL *)wmf_URLWithDomain:(NSString *)domain language:(nullable NSString *)language title:(nullable NSString *)title fragment:(nullable NSString *)fragment;

/**
 * Return a new URL constructed from the `siteURL`, replacing the `title` and `fragment` with the given values.
 *
 * @param siteURL       A Wikimedia site URL. For exmaple: `https://en.wikipedia.org`.
 * @param title         A Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 * @return A new URL constructed from the `siteURL`, replacing the `title` and `fragment` with the given values.
 **/
+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL title:(nullable NSString *)title fragment:(nullable NSString *)fragment;

/**
 * Return a new URL constructed from the `siteURL`, replacing the `path` with the `internalLink`.
 *
 * @param siteURL       A Wikimedia site URL. For exmaple: `https://en.wikipedia.org`.
 * @param internalLink  A Wikimedia internal link path. For exmaple: `/wiki/Main_Page#section`.
 *
 * @return A new URL constructed from the `siteURL`, replacing the `path` with the `internalLink`.
 **/
//WMF_TECH_DEBT_TODO(this method should be generecized to "path" and handle the presence of / wiki /)
+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL escapedDenormalizedInternalLink:(NSString *)internalLink;

/**
 * Return a new URL constructed from the `siteURL`, replacing the `path` with the internal link prefix and the `path`.
 *
 * @param siteURL                                       A Wikimedia site URL. For exmaple: `https://en.wikipedia.org`.
 * @param escapedDenormalizedTitleAndFragment           A Wikimedia path and fragment. For exmaple: `/Main_Page#section`.
 *
 * @return A new URL constructed from the `siteURL`, replacing the `path` with the internal link prefix and the `path`.
 **/
//WMF_TECH_DEBT_TODO(this method should be folded into the above method and should handle the presence of a #)
+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL escapedDenormalizedTitleAndFragment:(NSString *)escapedDenormalizedTitleAndFragment;

/**
 * Return a new URL constructed from the `siteURL`, replacing the `path` with the internal link prefix and the `path`.
 *
 * @param siteURL                                       A Wikimedia site URL. For exmaple: `https://en.wikipedia.org`.
 * @param unescapedDenormalizedTitleAndFragment           A Wikimedia path and fragment. For exmaple: `/99%_Invisible#section`. Note the % is not escaped.
 *
 * @return A new URL constructed from the `siteURL`, replacing the `path` with the internal link prefix and the `path`.
 **/
+ (NSURL *)wmf_URLWithSiteURL:(NSURL *)siteURL unescapedDenormalizedTitleAndFragment:(NSString *)unescapedDenormalizedTitleAndFragment;

/**
 *  Return a URL for the mobile API Endpoint for the current URL
 *
 *  @return return value description
 */
+ (NSURL *)wmf_mobileAPIURLForURL:(NSURL *)URL;

/**
 *  Return a URL for the desktop API Endpoint for the current URL
 *
 *  @return return value description
 */
+ (NSURL *)wmf_desktopAPIURLForURL:(NSURL *)URL;

/**
 *  Return the mobile version of the given URL
 *  by adding a m. subdomian
 *
 *  @param url The URL
 *
 *  @return Mobile version of the URL
 */
+ (NSURL *)wmf_mobileURLForURL:(NSURL *)url;

/**
 *  Return the desktop version of the given URL
 *  by removing a m. subdomian
 *
 *  @param url The URL
 *
 *  @return Mobile version of the URL
 */
+ (NSURL *)wmf_desktopURLForURL:(NSURL *)url;

/**
 * Return a new URL similar to the URL you call this method on but replace the title.
 *
 * @param title         A Wikimedia title. For exmaple: `Main Page`.
 *
 * @return A new URL based on the URL you call this method on with the given title.
 **/
- (NSURL *)wmf_URLWithTitle:(NSString *)title;

/**
 * Return a new URL similar to the URL you call this method on but replace the title and fragemnt.
 *
 * @param title         A Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 * @return A new URL based on the URL you call this method on with the given title and fragment.
 **/
- (NSURL *)wmf_URLWithTitle:(NSString *)title fragment:(nullable NSString *)fragment;

/**
 * Return a new URL similar to the URL you call this method on but replace the fragemnt.
 *
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 * @return A new URL based on the URL you call this method on with the given fragment.
 **/
- (NSURL *)wmf_URLWithFragment:(nullable NSString *)fragment;

/**
 * Return a new URL similar to the URL you call this method on but replace the path.
 *
 * @param path         A full path - for example `/w/api.php`
 *
 * @return A new URL based on the URL you call this method on with the given path.
 **/
- (NSURL *)wmf_URLWithPath:(NSString *)path isMobile:(BOOL)isMobile;

#pragma mark - URL Componenets

/**
 *  Return a URL with just the domain, language, and mobile subdomain of the reciever.
 *  Everything but the path
 *
 *  @return The site URL
 */
@property (nonatomic, copy, readonly) NSURL *wmf_siteURL;

@property (nonatomic, copy, readonly, nullable) NSString *wmf_domain;

@property (nonatomic, copy, readonly, nullable) NSString *wmf_language;

@property (nonatomic, copy, readonly, nullable) NSString *wmf_pathWithoutWikiPrefix;

@property (nonatomic, copy, readonly) NSString *wmf_title;

@property (nonatomic, copy, readonly) NSString *wmf_titleWithUnderScores;

#pragma mark - Introspection

/**
 *  Return YES is a URL is a link to a Wiki resource
 *  Checks for the presence of "/wiki/" in the path
 */
@property (nonatomic, readonly) BOOL wmf_isWikiResource;

/**
 *  Return YES if the receiver has "cite_note" in the path
 */
@property (nonatomic, readonly) BOOL wmf_isWikiCitation;

@property (nonatomic, readonly) BOOL wmf_isMainPage;

/**
 *  Return YES if the URL has a .m subdomain
 */
@property (nonatomic, readonly) BOOL wmf_isMobile;

/**
 *  Return YES if the URL does not have a language subdomain
 */
@property (nonatomic, readonly) BOOL wmf_isNonStandardURL;

@end

NS_ASSUME_NONNULL_END
