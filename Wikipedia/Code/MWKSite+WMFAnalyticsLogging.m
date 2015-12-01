

#import "MWKSite+WMFAnalyticsLogging.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKSite (WMFAnalyticsLogging)

- (NSString*)analyticsName {
    NSParameterAssert(self.language);
    NSParameterAssert(self.domain);
    if (self.language == nil || self.domain == nil) {
        return @"";
    }
    return [NSString stringWithFormat:@"%@.%@", self.language, self.domain];
}

@end

NS_ASSUME_NONNULL_END
