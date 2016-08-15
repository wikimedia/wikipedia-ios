//
//  MWKDataStore+TempDataStoreForEach.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/13/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataStore.h"

@interface MWKDataStore (TempDataStoreForEach)

+ (instancetype)configureTempDataStoreForEach:(void (^)(MWKDataStore *dataStore))configure;

@end

#define configureTempDataStoreForEach(_tempDataStore, _withConfigureBlock) \
    __block MWKDataStore *_tempDataStore;                                  \
    [MWKDataStore configureTempDataStoreForEach:^(MWKDataStore * ds) {     \
      _tempDataStore = ds;                                                 \
      _withConfigureBlock();                                               \
    }]
