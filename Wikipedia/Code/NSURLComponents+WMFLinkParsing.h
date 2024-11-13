#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLComponents (WMFLinkParsing)

/**
 * Create new NSURLComponents with a Wikimedia `domain` and `languageCode`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 *
 * @param languageCode  An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 *
 * @return New NSURLComponents with the given domain and languageCode.
 **/
+ (nonnull NSURLComponents *)wmf_componentsWithDomain:(nonnull NSString *)domain
                                         languageCode:(nullable NSString *)languageCode;
/**
 * Create new NSURLComponents with a Wikimedia `domain` and `languageCode` for the mobile or desktop site.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param languageCode  An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 * @param isMobile      A boolean indicating whether or not the returned URL components should be for the mobile version of the site.
 *
 * @return New NSURLComponents with the given domain and languageCode.
 **/
+ (nonnull NSURLComponents *)wmf_componentsWithDomain:(nonnull NSString *)domain
                                         languageCode:(nullable NSString *)languageCode
                                             isMobile:(BOOL)isMobile;

/**
 * Create new NSURLComponents with a Wikimedia `domain`, `language` and `title`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param languageCode  An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 * @param title         An optional Wikimedia title. For exmaple: `Main Page`.
 *
 * @return New NSURLComponents with the given domain, languageCode and title.
 **/
+ (nonnull NSURLComponents *)wmf_componentsWithDomain:(nonnull NSString *)domain
                                         languageCode:(nullable NSString *)languageCode
                                                title:(nullable NSString *)title;

/**
 * Create new NSURLComponents with a Wikimedia `domain`, `languageCode`, `title` and `fragment`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param languageCode  An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 * @param title         An optional Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 *
 * @return New NSURLComponents with the given domain, languageCode, title and fragment.
 **/
+ (NSURLComponents *__nonnull)wmf_componentsWithDomain:(nonnull NSString *)domain
                                          languageCode:(nullable NSString *)languageCode
                                                 title:(nullable NSString *)title
                                              fragment:(nullable NSString *)fragment;

/**
 * Create new NSURLComponents with a Wikimedia `domain`, `languageCode`, `title` and `fragment` for mobile or desktop based on `isMobile`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param languageCode  An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 * @param title         An optional Wikimedia title. For exmaple: `Main Page`.
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 * @param isMobile      A boolean indicating whether or not the returned URL components should be for the mobile version of the site.
 *
 * @return New NSURLComponents with the given domain, languageCode, title and fragment for mobile or desktop based on `isMobile`.
 **/
+ (nonnull NSURLComponents *)wmf_componentsWithDomain:(nonnull NSString *)domain
                                         languageCode:(nullable NSString *)languageCode
                                                title:(nullable NSString *)title
                                             fragment:(nullable NSString *)fragment
                                             isMobile:(BOOL)isMobile;

/**
 * Create new NSString containing the full host for a Wikimedia `domain` and `languageCode` for mobile or desktop based on `isMobile`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param languageCode   An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 * @param isMobile      A boolean indicating whether or not the returned URL components should be for the mobile version of the site.
 *
 * @return A new NSString containing the full host for a Wikimedia `domain` and `languageCode` for mobile or desktop based on `isMobile`.
 **/
+ (nonnull NSString *)wmf_hostWithDomain:(nonnull NSString *)domain
                            languageCode:(nullable NSString *)languageCode
                                isMobile:(BOOL)isMobile;

/**
 * Create new NSString containing the full host for a Wikimedia `domain` and `subDomain` for mobile or desktop based on `isMobile`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 * @param subDomain      An optional subDomain. For example `commons`.
 * @param isMobile      A boolean indicating whether or not the returned URL components should be for the mobile version of the site.
 *
 * @return A new NSString containing the full host for a Wikimedia `domain` and `subDomain` for mobile or desktop based on `isMobile`.
 **/
+ (nonnull NSString *)wmf_hostWithDomain:(nonnull NSString *)domain
                               subDomain:(nullable NSString *)subDomain
                                isMobile:(BOOL)isMobile;

@property (nonatomic, copy, nullable) NSString *wmf_title;
@property (nonatomic, copy, nullable) NSString *wmf_titleWithUnderscores;
@property (nullable, copy) NSString *wmf_fragment;

@property (nonatomic, readonly, nullable) NSString *wmf_eventLoggingLabel;
@property (nonatomic, readonly, nullable) NSURLComponents *wmf_componentsByRemovingInternalQueryParameters;

- (NSURLComponents *)wmf_componentsByRemovingQueryItemsNamed:(NSSet<NSString *> *)queryItemNames;
- (nullable NSString *)wmf_valueForQueryItemNamed:(NSString *)queryItemName;

/// Create an NSURL from the receiver's components and associates the provided @c languageVariantCode
- (nullable NSURL *)wmf_URLWithLanguageVariantCode:(nullable NSString *)code;

@end

NS_ASSUME_NONNULL_END
