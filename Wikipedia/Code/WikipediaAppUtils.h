@import Foundation;
#import <WMF/WMFDeprecationMacros.h>

NS_ASSUME_NONNULL_BEGIN

WMF_TECH_DEBT_DEPRECATED_MSG("This class is deprecated, its methods should be broken up into separate category methods.")
@interface WikipediaAppUtils : NSObject

+ (NSString *)appVersion;
+ (NSString *)formFactor;
+ (NSString *)versionedUserAgent;

+ (NSString *)assetsPath;

@end

NS_ASSUME_NONNULL_END
