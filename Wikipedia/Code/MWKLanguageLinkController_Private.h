#import <WMF/MWKLanguageLinkController.h>

NS_ASSUME_NONNULL_BEGIN

@interface MWKLanguageLinkController (WMFTesting)

/**
 * Reads previously selected languages from storage.
 * @return The preferred languages, or an empty array of none were previously added to the preferred list.
 */
- (NSArray<NSString *> *)readPreferredLanguageCodesWithoutOSPreferredLanguages;

/**
 * The same as above, but adds OS preferred languages if they are not in the array
 * @return The preferred languages.
 */
- (NSArray<NSString *> *)readPreferredLanguageCodes;

/**
 *  Loads the languages from the local file system
 */
- (void)loadLanguagesFromFile;

/**
 * Delete all previously selected languages.
 * calling readPreferredLanguageCodes will automatically restore the OS languages
 * @warning For testing only!
 */
- (void)resetPreferredLanguages;

/**
 *  Uniquely adds a new preferred language. The new language will be the first preferred language.
 *
 *  @param language the language to add
 */
- (void)addPreferredLanguage:(MWKLanguageLink *)language;

@end

NS_ASSUME_NONNULL_END
