#import <XCTest/XCTest.h>
#import "NSString+FormattedAttributedString.h"

@interface NSString_FormattedAttributedStringTests : XCTestCase

@property (nonatomic, strong) NSDictionary *largeOrangeText;
@property (nonatomic, strong) NSDictionary *smallGreenText;
@property (nonatomic, strong) NSDictionary *mediumBlueText;

@end

@implementation NSString_FormattedAttributedStringTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.largeOrangeText = @{
        NSFontAttributeName: [UIFont fontWithName:@"Georgia" size:20],
        NSForegroundColorAttributeName: [UIColor orangeColor]
    };
    self.smallGreenText = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:8],
        NSForegroundColorAttributeName: [UIColor greenColor]
    };
    self.mediumBlueText = @{
        NSFontAttributeName: [UIFont systemFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor blueColor],
        NSStrikethroughStyleAttributeName: @YES
    };
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testComplexAttributedStringCreation {
    // First create complex attributed string (complexAttributedString1) using our substitution method:
    // (Note the multiple occurences of "%1$@".)
    NSAttributedString *complexAttributedString1 =
        [@"Large orange text and some %1$@ and %2$@ text. More %1$@ text."
            attributedStringWithAttributes:self.largeOrangeText
                       substitutionStrings:@[@"small green", @"medium blue"]
                    substitutionAttributes:@[self.smallGreenText, self.mediumBlueText]];

    // Now create identical complex attributed string (complexAttributedString2) using standard methods:
    NSMutableAttributedString *complexAttributedString2 = [[NSMutableAttributedString alloc] init];
    [complexAttributedString2 appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"Large orange text and some " attributes:self.largeOrangeText]];
    [complexAttributedString2 appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"small green" attributes:self.smallGreenText]];
    [complexAttributedString2 appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@" and " attributes:self.largeOrangeText]];
    [complexAttributedString2 appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"medium blue" attributes:self.mediumBlueText]];
    [complexAttributedString2 appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@" text. More " attributes:self.largeOrangeText]];
    [complexAttributedString2 appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"small green" attributes:self.smallGreenText]];
    [complexAttributedString2 appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@" text." attributes:self.largeOrangeText]];

    // Test equality.
    XCTAssert([complexAttributedString1 isEqualToAttributedString:complexAttributedString2]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.

        for (NSInteger i = 0; i < 10000; i++) {
            [@"Large orange text and some %1$@ and %2$@ text. More %1$@ text."
                attributedStringWithAttributes:self.largeOrangeText
                           substitutionStrings:@[@"small green", @"medium blue"]
                        substitutionAttributes:@[self.smallGreenText, self.mediumBlueText]];
        }
    }];
}

@end
