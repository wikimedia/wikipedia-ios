#import <WMF/WMFLocalization.h>
#import <WMF/WMF-Swift.h>

// Note: we can't apply @objc to global Swift function WMFLocalizedString, so we are wrapping up Objective-C calls here
NSString *WMFLocalizedStringWithDefaultValue(NSString *key, NSString *_Nullable wikipediaLanguageCode, NSBundle *_Nullable bundle, NSString *value, NSString *comment) {
    return [WMFLocalizationWrapper wmf_NewLocalizedStringWithDefaultValue:key wikipediaLanguageCode:wikipediaLanguageCode bundle:bundle value:value comment:comment];
}
