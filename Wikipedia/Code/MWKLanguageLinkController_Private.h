
#import "MWKLanguageLinkController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MWKLanguageLinkController ()

/**
 * Reads previously selected languages from storage.
 * @return The preferred languages, or an empty array of none were previously added to the preferred list.
 */
- (NSArray<NSString*>*)readPreferredLanguageCodesWithoutOSPreferredLanguages;

/**
 * The same as above, but adds OS preferred languages if they are not in the array
 * @return The preferred languages.
 */
- (NSArray<NSString*>*)readPreferredLanguageCodes;

/**
 *  Loads the languages from the local file system
 */
- (void)loadLanguagesFromFile;


- (void)addPreferredLanguageForCode:(NSString*)languageCode;


- (void)appendPreferredLanguageForCode:(NSString*)languageCode;

/**
 * Delete all previously selected languages.
 * calling readPreferredLanguageCodes will automatically restore the OS languages
 * @warning For testing only!
 */
- (void)resetPreferredLanguages;


@end

NS_ASSUME_NONNULL_END
