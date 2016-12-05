#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFRandomFileUtilities.h"
#import "XCTestCase+WMFBundleConvenience.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKDataStore (Testing)

+ (instancetype)temporaryDataStore {
    return [[MWKDataStore alloc] initWithContainerURL:[NSURL fileURLWithPath:WMFRandomTemporaryPath()]];
}

@end

NS_ASSUME_NONNULL_END
