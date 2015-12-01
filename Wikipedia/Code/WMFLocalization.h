
#import <Foundation/Foundation.h>

@class MWKSite;

NSString* localizedStringForKeyFallingBackOnEnglish(NSString* key);

NSString* localizedStringForSiteWithKeyFallingBackOnEnglish(MWKSite* site, NSString* key);

#define MWLocalizedString(key, throwaway) localizedStringForKeyFallingBackOnEnglish(key)

#define MWSiteLocalizedString(site, key, throwaway) localizedStringForSiteWithKeyFallingBackOnEnglish(site, key)
