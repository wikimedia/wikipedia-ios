//
//  MWKDataStore+TempDataStoreForEach.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/13/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataStore+TempDataStoreForEach.h"
#import <Quick/Quick.h>
#import "MWKDataStore+TemporaryDataStore.h"

@implementation MWKDataStore (TempDataStoreForEach)

+ (instancetype)configureTempDataStoreForEach:(void (^)(MWKDataStore *dataStore))configure {
    __block MWKDataStore *dataStore;
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
