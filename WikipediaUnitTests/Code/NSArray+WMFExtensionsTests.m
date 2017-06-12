#import <XCTest/XCTest.h>
#import "Wikipedia-Swift.h"
#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface NSArray_WMFExtensionsTests : XCTestCase

@property (strong, nonatomic) NSArray *array;
@property (strong, nonatomic) NSArray *otherArray;

@end

@implementation NSArray_WMFExtensionsTests

- (void)setUp {
    [super setUp];
    self.array = @[@"one", @"two"];
    self.otherArray = @[@1, @2, @3];
}

- (void)tearDown {
    self.array = nil;
    self.otherArray = nil;
    [super tearDown];
}

- (void)test_wmf_arrayByTrimmingToLength_ZeroReturnsEmpty {
    NSArray *array = @[@"bla"];
    assertThat([array wmf_arrayByTrimmingToLength:0], is(@[]));
}

- (void)test_wmf_arrayByTrimmingToLength_NegativeReturnsSelf {
    NSArray *array = @[@"bla"];
    assertThat([array wmf_arrayByTrimmingToLength:-10], is(array));
}

- (void)test_wmf_arrayByTrimmingToLength_countZeroReturnsSelf {
    NSArray *emptyArray = @[];
    assertThat([emptyArray wmf_arrayByTrimmingToLength:5], is(emptyArray));
}

- (void)test_wmf_arrayByTrimmingToLength_arraySmallerThanRequestedLength {
    assertThat([self.array wmf_arrayByTrimmingToLength:3], is(self.array));
}

- (void)test_wmf_arrayByTrimmingToLength_trimToCount {
    assertThat([self.array wmf_arrayByTrimmingToLength:1], hasCountOf(1));
}

- (void)test_wmf_arrayByTrimmingToLength_trimToExpectedResult {
    assertThat([self.array wmf_arrayByTrimmingToLength:1][0], is(@"one"));
}

- (void)test_wmf_arrayByTrimmingToLengthFromEnd_emptyZeroReturnsSelf {
    NSArray *array = @[];
    assertThat([array wmf_arrayByTrimmingToLengthFromEnd:0], is(array));
}

- (void)test_wmf_arrayByTrimmingToLengthFromEnd_nonEmptyZeroReturnsEmpty {
    NSArray *array = @[@"one"];
    assertThat([array wmf_arrayByTrimmingToLengthFromEnd:0], is(@[]));
}

- (void)test_wmf_arrayByTrimmingToLengthFromEnd_nonEmptyNegativeReturnsSelf {
    NSArray *array = @[@"one"];
    assertThat([array wmf_arrayByTrimmingToLengthFromEnd:-10], is(array));
}

- (void)test_wmf_arrayByTrimmingToLengthFromEnd_countZeroReturnsSelf {
    NSArray *emptyArray = @[];
    assertThat([emptyArray wmf_arrayByTrimmingToLengthFromEnd:5], is(emptyArray));
}

- (void)test_wmf_arrayByTrimmingToLengthFromEnd_arraySmallerThanRequestedLength {
    assertThat([self.array wmf_arrayByTrimmingToLengthFromEnd:3], is(self.array));
}

- (void)test_wmf_arrayByTrimmingToLengthFromEnd_trimToCount {
    assertThat([self.array wmf_arrayByTrimmingToLengthFromEnd:1], hasCountOf(1));
}

- (void)test_wmf_arrayByTrimmingToLengthFromEnd_trimToExpectedResult {
    assertThat([self.array wmf_arrayByTrimmingToLengthFromEnd:1][0], is(@"two"));
}

- (void)test_wmf_reverseArray {
    assertThat([self.array wmf_reverseArray], is(@[@"two", @"one"]));
}

- (void)testSafeSubarrayShouldLimitToCount {
    NSArray *original = @[@0, @1];
    assertThat([original wmf_safeSubarrayWithRange:NSMakeRange(0, 5)], is(original));
}

- (void)testSafeSubarrayShouldReturnEmptyArrayIfRangeLocationOutOfBounds {
    assertThat(([@[@0, @1] wmf_safeSubarrayWithRange:NSMakeRange(2, 1)]), isEmpty());
}

- (void)testSafeSubarrayShouldReturnEmptyIfRangeIsNotFound {
    assertThat(([@[@0, @1] wmf_safeSubarrayWithRange:NSMakeRange(NSNotFound, 1)]), isEmpty());
}

- (void)testSafeSubarrayShouldReturnEmptyIfRangeIsEmpty {
    assertThat(([@[@0, @1] wmf_safeSubarrayWithRange:NSMakeRange(0, 0)]), isEmpty());
}

- (void)testSafeSubarrayShouldReturnEmptyFromEmptyList {
    assertThat(([@[] wmf_safeSubarrayWithRange:NSMakeRange(0, 1)]), isEmpty());
}

- (void)testArrayByRemovingFirstElement_shouldReturnAllButTheFirstElement {
    assertThat(([@[@0, @1] wmf_arrayByRemovingFirstElement]), is(equalTo(@[@1])));
}

- (void)testArrayByRemovingFirstElement_shouldReturnEmptyArrayFromSingletonList {
    assertThat(([@[@1] wmf_arrayByRemovingFirstElement]), isEmpty());
}

- (void)testArrayByRemovingFirstElement_shouldReturnEmptyArrayFromEmptyList {
    assertThat(([@[] wmf_arrayByRemovingFirstElement]), isEmpty());
}

- (void)testArrayByInterleaving_firstObject {
    assertThat([self.array wmf_arrayByInterleavingElementsFromArray:self.otherArray][0], is(@"one"));
}

- (void)testArrayByInterleaving_secondObject {
    assertThat([self.array wmf_arrayByInterleavingElementsFromArray:self.otherArray][1], is(@1));
}

- (void)testArrayByInterleaving_lastObject {
    assertThat([[self.array wmf_arrayByInterleavingElementsFromArray:self.otherArray] lastObject], is(@3));
}

- (void)testArrayByInterleaving_firstObjectOtherArray {
    assertThat([self.otherArray wmf_arrayByInterleavingElementsFromArray:self.array][0], is(@1));
}

- (void)testArrayByInterleaving_secondObjectOtherArray {
    assertThat([self.otherArray wmf_arrayByInterleavingElementsFromArray:self.array][1], is(@"one"));
}

- (void)testArrayByInterleaving_lastObjectOtherArray {
    assertThat([[self.otherArray wmf_arrayByInterleavingElementsFromArray:self.array] lastObject], is(@3));
}

@end
