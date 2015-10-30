
#import "MWKSearchRedirectMapping.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKSearchRedirectMapping

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
    return @{
               WMF_SAFE_KEYPATH(MWKSearchRedirectMapping.new, redirectFromTitle): @"from",
               WMF_SAFE_KEYPATH(MWKSearchRedirectMapping.new, redirectToTitle): @"to",
    };
}

@end

NS_ASSUME_NONNULL_END