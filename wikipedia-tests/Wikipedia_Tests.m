//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <XCTest/XCTest.h>

@interface Wikipedia_Tests : XCTestCase

@end

@implementation Wikipedia_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    NSLog(@"done"); // crazy hack for "tests not finished"
    [super tearDown];
}

- (void)testExample
{
    XCTAssert(YES, @"Confirming tests work!");
}

@end
