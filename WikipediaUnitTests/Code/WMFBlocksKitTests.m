#import <XCTest/XCTest.h>
@import WMF;

@interface WMFBlocksKitTests : XCTestCase

@end

@implementation WMFBlocksKitTests

- (void)testNils {
    NSArray *array = @[@1, @2];
    NSArray *transformedArray = [array wmf_map:^id _Nullable(id _Nonnull obj) {
        return nil;
    }];
    NSArray *nullArray = @[[NSNull null], [NSNull null]];
    XCTAssertEqualObjects(transformedArray, nullArray);

    NSSet *set = [NSSet setWithArray:nullArray];
    NSSet *transformedSet = [set wmf_map:^id _Nullable(id _Nonnull obj) {
        return nil;
    }];
    NSSet *nullSet = [NSSet setWithObject:[NSNull null]];
    XCTAssertEqualObjects(transformedSet, nullSet);

    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:@[@1, @2, @3, @4] forKeys:@[@"A", @"B", @"C", @"D"]];
    NSDictionary *mappedDictionary = [dictionary wmf_map:^id _Nullable(id _Nonnull key, id _Nonnull value) {
        return [value integerValue] % 2 == 0 ? nil : value;
    }];
    NSDictionary *nullDictionary = @{ @"A": @1,
                                      @"B": [NSNull null],
                                      @"C": @3,
                                      @"D": [NSNull null] };
    XCTAssertEqualObjects(mappedDictionary, nullDictionary);
}

- (void)testSelect {
    NSArray *array = @[@1, @2, @3, @4];
    NSArray *selectedArray = [array wmf_select:^BOOL(id _Nonnull obj) {
        return [obj integerValue] % 2 == 0;
    }];
    NSArray *evens = @[@2, @4];
    XCTAssertEqualObjects(selectedArray, evens);
    NSArray *rejectedArray = [array wmf_reject:^BOOL(id _Nonnull obj) {
        return [obj integerValue] % 2 == 0;
    }];
    NSArray *odds = @[@1, @3];
    XCTAssertEqualObjects(rejectedArray, odds);

    NSSet *set = [NSSet setWithArray:array];
    NSSet *selectedSet = [set wmf_select:^BOOL(id _Nonnull obj) {
        return [obj integerValue] % 2 == 0;
    }];
    XCTAssertEqualObjects(selectedSet, [NSSet setWithArray:evens]);
    NSSet *rejectedSet = [set wmf_reject:^BOOL(id _Nonnull obj) {
        return [obj integerValue] % 2 == 0;
    }];
    XCTAssertEqualObjects(rejectedSet, [NSSet setWithArray:odds]);

    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:array forKeys:@[@"A", @"B", @"C", @"D"]];
    NSDictionary *selectedDictionary = [dictionary wmf_select:^BOOL(id _Nonnull key, id _Nonnull value) {
        return [value integerValue] % 2 == 0;
    }];
    NSDictionary *evensDictionary = @{ @"B": @2,
                                       @"D": @4 };
    XCTAssertEqualObjects(selectedDictionary, evensDictionary);
}

- (void)testMatch {
    NSArray *array = @[@1, @2, @3, @4];
    NSNumber *match = [array wmf_match:^BOOL(id _Nonnull obj) {
        return [obj integerValue] % 2 == 0;
    }];
    XCTAssertEqualObjects(match, @2);

    NSSet *set = [NSSet setWithObjects:@1, @3, @5, @7, @8, nil];
    match = [set wmf_match:^BOOL(id _Nonnull obj) {
        return [obj integerValue] % 2 == 0;
    }];
    XCTAssertEqualObjects(match, @8);

    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:array forKeys:@[@"A", @"B", @"C", @"D"]];
    match = [dictionary wmf_match:^BOOL(id _Nonnull key, id _Nonnull value) {
        return [value integerValue] == 3;
    }];
    XCTAssertEqualObjects(match, @3);
}

@end
