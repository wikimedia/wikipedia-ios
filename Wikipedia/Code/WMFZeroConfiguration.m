#import <WMF/WMFZeroConfiguration.h>
#import "MTLValueTransformer+WMFColorTransformer.h"
#import <WMF/WMFComparison.h>

@implementation WMFZeroConfiguration

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
#define WMFZeroConfigurationKey(key) WMF_SAFE_KEYPATH([WMFZeroConfiguration new], key)
    return @{WMFZeroConfigurationKey(message): @"message",
             WMFZeroConfigurationKey(foreground): @"foreground",
             WMFZeroConfigurationKey(background): @"background",
             WMFZeroConfigurationKey(exitTitle): @"exitTitle",
             WMFZeroConfigurationKey(exitWarning): @"exitWarning",
             WMFZeroConfigurationKey(partnerInfoText): @"partnerInfoText",
             WMFZeroConfigurationKey(partnerInfoUrl): @"partnerInfoUrl",
             WMFZeroConfigurationKey(bannerUrl): @"bannerUrl"};
}

+ (MTLValueTransformer *)foregroundJSONTransformer {
    return [MTLValueTransformer wmf_forwardHexColorTransformer];
}

+ (MTLValueTransformer *)backgroundJSONTransformer {
    return [MTLValueTransformer wmf_forwardHexColorTransformer];
}

- (BOOL)hasPartnerInfoTextAndURL {
    return self.partnerInfoText != nil && self.partnerInfoUrl != nil;
}

@end
