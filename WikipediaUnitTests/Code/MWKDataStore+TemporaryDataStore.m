#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFRandomFileUtilities.h"
#import "XCTestCase+WMFBundleConvenience.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKDataStore (Testing)

+ (void)createTemporaryDataStoreWithCompletion:(void (^)(MWKDataStore *))completion {
    MWKDataStore *dataStore = [[MWKDataStore alloc] initWithContainerURL:[NSURL fileURLWithPath:WMFRandomTemporaryPath()]];
    [dataStore finishSetup:^{
        [dataStore performInitialLibrarySetup];
        [dataStore performTestLibrarySetup];
        if (completion) {
            completion(dataStore);
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
