//
//  XCTestCase+DataStoreFixtureTesting.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCTestCase (MWKDataStoreFixtureTesting)

- (nullable MWKDataStore *)wmf_temporaryCopyOfDataStoreFixtureAtPath:(NSString *)relativeFolderPath;

@end

NS_ASSUME_NONNULL_END
