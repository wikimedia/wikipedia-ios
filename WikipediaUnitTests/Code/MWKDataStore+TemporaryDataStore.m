#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFRandomFileUtilities.h"
#import "XCTestCase+WMFBundleConvenience.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKDataStore (Testing)

+ (instancetype)temporaryDataStore {
    return [[MWKDataStore alloc] initWithBasePath:WMFRandomTemporaryPath()];
}

@end

NS_ASSUME_NONNULL_END
