@import XCTest;

@interface NSDictionaryBlocksKitTest : XCTestCase

@end

@implementation NSDictionaryBlocksKitTest {
    NSDictionary *_subject;
    NSInteger _total;
}

- (void)setUp {
    _subject = @{
        @"1": @(1),
        @"2": @(2),
        @"3": @(3),
    };
    _total = 0;
}

- (void)tearDown {
    _subject = nil;
}

- (void)testMatch {
    BOOL (^validationBlock)(id, id) = ^(id key, id value) {
        self->_total += [value intValue] + [key intValue];
        BOOL select = [value intValue] < 3 ? YES : NO;
        return select;
    };
    NSDictionary *selected = [_subject wmf_match:validationBlock];
    XCTAssertEqual(_total, (NSInteger)2, @"2*1 = %ld", (long)_total);
    XCTAssertEqualObjects(selected, @(1), @"selected value is %@", selected);
}

- (void)testSelect {
    BOOL (^validationBlock)(id, id) = ^(id key, id value) {
        self->_total += [value intValue] + [key intValue];
        BOOL select = [value intValue] < 3 ? YES : NO;
        return select;
    };
    NSDictionary *selected = [_subject wmf_select:validationBlock];
    XCTAssertEqual(_total, (NSInteger)12, @"2*(1+2+3) = %ld", (long)_total);
    NSDictionary *target = @{ @"1": @(1),
                              @"2": @(2) };
    XCTAssertEqualObjects(selected, target, @"selected dictionary is %@", selected);
}

- (void)testSelectedNone {
    BOOL (^validationBlock)(id, id) = ^(id key, id value) {
        self->_total += [value intValue] + [key intValue];
        BOOL select = [value intValue] > 4 ? YES : NO;
        return select;
    };
    NSDictionary *selected = [_subject wmf_select:validationBlock];
    XCTAssertEqual(_total, (NSInteger)12, @"2*(1+2+3) = %ld", (long)_total);
    XCTAssertTrue(selected.count == 0, @"none item is selected");
}

- (void)testReject {
    BOOL (^validationBlock)(id, id) = ^(id key, id value) {
        self->_total += [value intValue] + [key intValue];
        BOOL reject = [value intValue] < 3 ? YES : NO;
        return reject;
    };
    NSDictionary *rejected = [_subject wmf_reject:validationBlock];
    XCTAssertEqual(_total, (NSInteger)12, @"2*(1+2+3) = %ld", (long)_total);
    NSDictionary *target = @{ @"3": @(3) };
    XCTAssertEqualObjects(rejected, target, @"dictionary after rejection is %@", rejected);
}

- (void)testRejectedAll {
    BOOL (^validationBlock)(id, id) = ^(id key, id value) {
        self->_total += [value intValue] + [key intValue];
        BOOL reject = [value intValue] < 4 ? YES : NO;
        return reject;
    };
    NSDictionary *rejected = [_subject wmf_reject:validationBlock];
    XCTAssertEqual(_total, (NSInteger)12, @"2*(1+2+3) = %ld", (long)_total);
    XCTAssertTrue(rejected.count == 0, @"all items are selected");
}

- (void)testMap {
    id (^transformBlock)(id, id) = ^id(id key, id value) {
        self->_total += [value intValue] + [key intValue];
        return @(self->_total);
    };
    NSDictionary *transformed = [_subject wmf_map:transformBlock];
    XCTAssertEqual(_total, (NSInteger)12, @"2*(1+2+3) = %ld", (long)_total);
    NSDictionary *target = @{ @"1": @(2),
                              @"2": @(6),
                              @"3": @(12) };
    XCTAssertEqualObjects(transformed, target, @"transformed dictionary is %@", transformed);
}

@end
