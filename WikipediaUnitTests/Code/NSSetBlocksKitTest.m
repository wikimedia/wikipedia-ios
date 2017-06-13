@import XCTest;

@interface NSSetBlocksKitTest : XCTestCase

@end

@implementation NSSetBlocksKitTest {
    NSSet *_subject;
    NSInteger _total;
}

- (void)setUp {
    _subject = [NSSet setWithArray:@[@"1", @"22", @"333"]];
    _total = 0;
}

- (void)testMatch {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] == 22) ? YES : NO;
        return match;
    };
    id found = [_subject wmf_match:validationBlock];
    XCTAssertEqual(_total, (NSInteger)3, @"total length of \"122\" is %ld", (long)_total);
    XCTAssertEqual(found, @"22", @"matched object is %@", found);
}

- (void)testNotMatch {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] == 4444) ? YES : NO;
        return match;
    };
    id found = [_subject wmf_match:validationBlock];
    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    XCTAssertNil(found, @"no matched object");
}

- (void)testSelect {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] < 300) ? YES : NO;
        return match;
    };
    NSSet *found = [_subject wmf_select:validationBlock];

    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    NSSet *target = [NSSet setWithArray:@[@"1", @"22"]];
    XCTAssertEqualObjects(found, target, @"selected items are %@", found);
}

- (void)testSelectedNone {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] > 400) ? YES : NO;
        return match;
    };
    NSSet *found = [_subject wmf_select:validationBlock];
    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    XCTAssertTrue(found.count == 0, @"no item is selected");
}

- (void)testReject {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] > 300) ? YES : NO;
        return match;
    };
    NSSet *left = [_subject wmf_reject:validationBlock];
    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    NSSet *target = [NSSet setWithArray:@[@"1", @"22"]];
    XCTAssertEqualObjects(left, target, @"not rejected items are %@", left);
}

- (void)testRejectedAll {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] < 400) ? YES : NO;
        return match;
    };
    NSSet *left = [_subject wmf_reject:validationBlock];
    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    XCTAssertTrue(left.count == 0, @"all items are rejected");
}

- (void)testMap {
    id (^transformBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        return [obj substringToIndex:1];
    };
    NSSet *transformed = [_subject wmf_map:transformBlock];

    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    NSSet *target = [NSSet setWithArray:@[@"1", @"2", @"3"]];
    XCTAssertEqualObjects(transformed, target, @"transformed items are %@", transformed);
}

- (void)testReduceWithBlock {
    id (^accumlationBlock)(id, id) = ^(NSString *sum, NSString *obj) {
        return [sum stringByAppendingString:obj];
    };
    NSString *concatenated = [_subject wmf_reduce:@"" withBlock:accumlationBlock];
    XCTAssertTrue([concatenated isEqualToString:@"122333"], @"concatenated string is %@", concatenated);
}

@end
