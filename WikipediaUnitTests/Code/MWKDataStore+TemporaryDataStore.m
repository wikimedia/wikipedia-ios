#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFRandomFileUtilities.h"
#import "XCTestCase+WMFBundleConvenience.h"
#import "YapDatabase+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKDataStore (Testing)

+ (instancetype)temporaryDataStore {
    return [[MWKDataStore alloc] initWithDatabase:[YapDatabase wmf_databaseWithDefaultConfigurationAtPath:WMFRandomTemporaryPath()] legacyDataBasePath:WMFRandomTemporaryPath()];
}

@end

NS_ASSUME_NONNULL_END
