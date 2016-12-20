#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
// See docs/localizations.md for high-level documentation

NSString *localizedStringForKeyFallingBackOnEnglish(NSString *key);

NSString *localizedStringForURLWithKeyFallingBackOnEnglish(NSURL *url, NSString *key);

#define MWLocalizedString(key, throwaway) localizedStringForKeyFallingBackOnEnglish(key)

#define MWSiteLocalizedString(url, key, throwaway) localizedStringForURLWithKeyFallingBackOnEnglish(url, key)

NS_ASSUME_NONNULL_END
