#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFRandomFileUtilities.h"
#import "XCTestCase+WMFBundleConvenience.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKDataStore (Testing)

+ (instancetype)temporaryDataStore {
    MWKDataStore *dataStore = [[MWKDataStore alloc] initWithContainerURL:[NSURL fileURLWithPath:WMFRandomTemporaryPath()]];
    [dataStore performUpdatesFromLibraryVersion:0 inManagedObjectContext:dataStore.viewContext];
    return dataStore;
}

@end

NS_ASSUME_NONNULL_END
