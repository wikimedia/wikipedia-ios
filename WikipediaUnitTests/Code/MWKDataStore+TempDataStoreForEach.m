#import "MWKDataStore+TempDataStoreForEach.h"
#import <Quick/Quick.h>
#import "MWKDataStore+TemporaryDataStore.h"

@implementation MWKDataStore (TempDataStoreForEach)

+ (instancetype)configureTempDataStoreForEach:(void (^)(MWKDataStore* dataStore))configure {
    __block MWKDataStore* dataStore;
    beforeEach(^{
        dataStore = [self temporaryDataStore];
        configure(dataStore);
    });
    afterEach(^{
        [dataStore removeFolderAtBasePath];
    });
    return dataStore;
}

@end
