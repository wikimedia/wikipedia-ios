@import Foundation;

@interface NSURL (WMFMainPage)

/**
 * Initialize a new URL with the main page URL for a given language anf the default domain - wikipedia.org.
 *
 * @param language      An optional Wikimedia language code. Should be ISO 639-x/IETF BCP 47 @see kCFLocaleLanguageCode - for example: `en`.
 *
 * @return A main page URL for the given language.
 **/
+ (nullable NSURL *)wmf_mainPageURLForLanguage:(nonnull NSString *)language;

@property (nonatomic, readonly) BOOL wmf_isMainPage;

@end
