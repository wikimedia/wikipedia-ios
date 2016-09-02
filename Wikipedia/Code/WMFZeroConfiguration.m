#import "WMFZeroConfiguration.h"
#import "MTLValueTransformer+WMFColorTransformer.h"

@implementation WMFZeroConfiguration

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
#define WMFZeroConfigurationKey(key) WMF_SAFE_KEYPATH([WMFZeroConfiguration new], key)
    return @{ WMFZeroConfigurationKey(message): @"message",
              WMFZeroConfigurationKey(foreground): @"foreground",
              WMFZeroConfigurationKey(background): @"background",
              WMFZeroConfigurationKey(exitTitle): @"exitTitle",
              WMFZeroConfigurationKey(exitWarning): @"exitWarning",
              WMFZeroConfigurationKey(partnerInfoText): @"partnerInfoText",
              WMFZeroConfigurationKey(partnerInfoUrl): @"partnerInfoUrl",
              WMFZeroConfigurationKey(bannerUrl): @"bannerUrl" };
}

+ (MTLValueTransformer *)foregroundJSONTransformer {
    return [MTLValueTransformer wmf_forwardHexColorTransformer];
}

+ (MTLValueTransformer *)backgroundJSONTransformer {
    return [MTLValueTransformer wmf_forwardHexColorTransformer];
}

@end
