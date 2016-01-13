
#import <Foundation/Foundation.h>

@class MWKSite;

// See docs/localizations.md for high-level documentation

NSString* localizedStringForKeyFallingBackOnEnglish(NSString* key);

NSString* localizedStringForSiteWithKeyFallingBackOnEnglish(MWKSite* site, NSString* key);

#define MWLocalizedString(key, throwaway) localizedStringForKeyFallingBackOnEnglish(key)

#define MWSiteLocalizedString(site, key, throwaway) localizedStringForSiteWithKeyFallingBackOnEnglish(site, key)
