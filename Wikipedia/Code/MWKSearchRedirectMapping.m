#import "MWKSearchRedirectMapping.h"
@import WMF.WMFComparison;

NS_ASSUME_NONNULL_BEGIN

@interface MWKSearchRedirectMapping ()

@property (nonatomic, copy, readwrite) NSString *redirectFromTitle;
@property (nonatomic, copy, readwrite) NSString *redirectToTitle;

@end

@implementation MWKSearchRedirectMapping

+ (instancetype)mappingFromTitle:(NSString *)from toTitle:(NSString *)to {
    MWKSearchRedirectMapping *instance = [self new];
    instance.redirectFromTitle = from;
    instance.redirectToTitle = to;
    return instance;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        WMF_SAFE_KEYPATH(MWKSearchRedirectMapping.new, redirectFromTitle): @"from",
        WMF_SAFE_KEYPATH(MWKSearchRedirectMapping.new, redirectToTitle): @"to",
    };
}

// No languageVariantCodePropagationSubelementKeys
// No languageVariantCodePropagationURLKeys

@end

NS_ASSUME_NONNULL_END
