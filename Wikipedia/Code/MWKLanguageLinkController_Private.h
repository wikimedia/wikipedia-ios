#import <WMF/MWKLanguageLinkController.h>

NS_ASSUME_NONNULL_BEGIN

@interface MWKLanguageLinkController (WMFTesting)

/**
 * Reads previously selected languages from storage.
 * @return The preferred languages, or an empty array if none were previously added to the preferred list.
 */
- (NSArray<NSString *> *)readSavedPreferredLanguageCodes;

/**
 * Delete all previously selected languages.
 * calling preferredLanguages will automatically restore the OS languages
 * @warning For testing only!
 */
- (void)resetPreferredLanguages;

@end

NS_ASSUME_NONNULL_END
