@import XCTest;

@interface NSArrayBlocksKitTest : XCTestCase

@end

@implementation NSArrayBlocksKitTest {
    NSArray *_subject;
    NSArray *_integers;
    NSArray *_floats;
    NSInteger _total;
}

- (void)setUp {
    _subject = @[@"1", @"22", @"333"];
    _integers = @[@(1), @(2), @(3)];
    _floats = @[@(.1), @(.2), @(.3)];
    _total = 0;
}

- (void)tearDown {
    _subject = nil;
}

- (void)testMatch {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] == 22) ? YES : NO;
        return match;
    };
    id found = [_subject wmf_match:validationBlock];

    // wmf_match: is functionally identical to wmf_select:, but will stop and return on the first match
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

    // @return Returns the object if found, `nil` otherwise.
    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    XCTAssertNil(found, @"no matched object");
}

- (void)testSelect {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] < 300) ? YES : NO;
        return match;
    };
    NSArray *found = [_subject wmf_select:validationBlock];

    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    NSArray *target = @[@"1", @"22"];
    XCTAssertEqualObjects(found, target, @"selected items are %@", found);
}

- (void)testSelectedNone {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] > 400) ? YES : NO;
        return match;
    };
    NSArray *found = [_subject wmf_select:validationBlock];

    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    XCTAssertTrue(found.count == 0, @"no item is selected");
}

- (void)testReject {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] > 300) ? YES : NO;
        return match;
    };
    NSArray *left = [_subject wmf_reject:validationBlock];

    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    NSArray *target = @[@"1", @"22"];
    XCTAssertEqualObjects(left, target, @"not rejected items are %@", left);
}

- (void)testRejectedAll {
    BOOL (^validationBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        BOOL match = ([obj intValue] < 400) ? YES : NO;
        return match;
    };
    NSArray *left = [_subject wmf_reject:validationBlock];

    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    XCTAssertTrue(left.count == 0, @"all items are rejected");
}

- (void)testMap {
    id (^transformBlock)(id) = ^(NSString *obj) {
        self->_total += [obj length];
        return [obj substringToIndex:1];
    };
    NSArray *transformed = [_subject wmf_map:transformBlock];

    XCTAssertEqual(_total, (NSInteger)6, @"total length of \"122333\" is %ld", (long)_total);
    NSArray *target = @[@"1", @"2", @"3"];
    XCTAssertEqualObjects(transformed, target, @"transformed items are %@", transformed);
}

- (void)testReduceWithBlock {
    id (^accumlationBlock)(id, id) = ^(id sum, id obj) {
        return [sum stringByAppendingString:obj];
    };
    NSString *concatenated = [_subject wmf_reduce:@"" withBlock:accumlationBlock];
    XCTAssertTrue([concatenated isEqualToString:@"122333"], @"concatenated string is %@", concatenated);
}

@end
