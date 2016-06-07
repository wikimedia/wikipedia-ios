#import <Foundation/Foundation.h>

@interface NSURLComponents (WMFLinkParsing)

/**
 * Create new NSURLComponents with a Wikimedia `domain` and `language`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 *
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 *
 * @return New NSURLComponents with the given domain and language.
 **/
+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language;
/**
 * Create new NSURLComponents with a Wikimedia `domain` and `language` for the mobile or desktop site.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 *
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 *
 * @param isMobile      A boolean indicating whether or not the returned URL components should be for the mobile version of the site.
 *
 * @return New NSURLComponents with the given domain and language.
 **/
+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language
                                              isMobile:(BOOL)isMobile;

/**
 * Create new NSURLComponents with a Wikimedia `domain`, `language` and `title`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 *
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 *
 * @param title         An optional Wikimedia title. for exmaple: `Main Page`.
 *
 * @return New NSURLComponents with the given domain, language and title.
 **/
+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language
                                                 title:(NSString* __nullable)title;

/**
 * Create new NSURLComponents with a Wikimedia `domain`, `language`, `title` and `fragment`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 *
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 *
 * @param title         An optional Wikimedia title. for exmaple: `Main Page`.
 *
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 *
 * @return New NSURLComponents with the given domain, language, title and fragment.
 **/
+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language
                                                 title:(NSString* __nullable)title
                                              fragment:(NSString* __nullable)fragment;

/**
 * Create new NSURLComponents with a Wikimedia `domain`, `language`, `title` and `fragment` for mobile or desktop based on `isMobile`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 *
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 *
 * @param title         An optional Wikimedia title. for exmaple: `Main Page`.
 *
 * @param fragment      An optional fragment, for example if you want the URL to contain `#section`, the fragment is `section`.
 *
 * @param isMobile      A boolean indicating whether or not the returned URL components should be for the mobile version of the site.
 *
 * @return New NSURLComponents with the given domain, language, title and fragment for mobile or desktop based on `isMobile`.
 **/
+ (NSURLComponents* __nonnull)wmf_componentsWithDomain:(NSString* __nonnull)domain
                                              language:(NSString* __nullable)language
                                                 title:(NSString* __nullable)title
                                              fragment:(NSString* __nullable)fragment
                                              isMobile:(BOOL)isMobile;

/**
 * Create new NSString containing the full host for a Wikimedia `domain` and `language` for mobile or desktop based on `isMobile`.
 *
 * @param domain        Wikimedia domain - for example: `wikimedia.org`.
 *
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for exmaple: `en`.
 *
 * @param isMobile      A boolean indicating whether or not the returned URL components should be for the mobile version of the site.
 *
 * @return A new NSString containing the full host for a Wikimedia `domain` and `language` for mobile or desktop based on `isMobile`.
 **/
+ (NSString* __nonnull)wmf_hostWithDomain:(NSString* __nonnull)domain
                                 language:(NSString* __nullable)language
                                 isMobile:(BOOL)isMobile;

@property (nonatomic, copy, nullable) NSString* wmf_title;
@property (nullable, copy) NSString* wmf_fragment;

@end
