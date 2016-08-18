#import "MWKDataStore.h"

@interface MWKDataStore (TempDataStoreForEach)

+ (instancetype)configureTempDataStoreForEach:(void (^)(MWKDataStore *dataStore))configure;

@end

#define configureTempDataStoreForEach(_tempDataStore, _withConfigureBlock) \
    __block MWKDataStore *_tempDataStore;                                  \
    [MWKDataStore configureTempDataStoreForEach:^(MWKDataStore * ds) {     \
        _tempDataStore = ds;                                               \
        _withConfigureBlock();                                             \
    }]
