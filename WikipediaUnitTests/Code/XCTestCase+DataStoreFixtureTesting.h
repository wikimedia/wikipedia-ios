#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCTestCase (MWKDataStoreFixtureTesting)

- (nullable MWKDataStore *)wmf_temporaryCopyOfDataStoreFixtureAtPath:(NSString *)relativeFolderPath;

@end

NS_ASSUME_NONNULL_END
