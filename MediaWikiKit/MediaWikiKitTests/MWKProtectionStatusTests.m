//
//  MWKProtectionStatusTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MWKTestCase.h"

@interface MWKProtectionStatusTests : MWKTestCase

@end

@implementation MWKProtectionStatusTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEmpty {
    id data = [self loadJSON:@"protection-empty"];
    MWKProtectionStatus *protection = [[MWKProtectionStatus alloc] initWithData:data];
    
    XCTAssertNotNil(protection);
    XCTAssertEqual([[protection protectedActions] count], 0);
}

- (void)testObama {
    id data = [self loadJSON:@"protection-obama"];
    MWKProtectionStatus *protection = [[MWKProtectionStatus alloc] initWithData:data];
    
    XCTAssertNotNil(protection);
    NSArray *actions = [protection protectedActions];
    XCTAssertEqual([actions count], 2);
    
    for (NSString *action in actions) {
        NSArray *groups = [protection allowedGroupsForAction:action];
        if ([action isEqualToString:@"edit"]) {
            XCTAssertEqual([groups count], 1);
            XCTAssertEqualObjects(groups[0], @"autoconfirmed");
        } else if ([action isEqualToString:@"move"]) {
            XCTAssertEqual([groups count], 1);
            XCTAssertEqualObjects(groups[0], @"sysop");
        }
    }
}

- (void)testEquals
{
    id dataEmpty = [self loadJSON:@"protection-empty"];
    id dataObama = [self loadJSON:@"protection-obama"];
    MWKProtectionStatus *protectionEmpty1 = [[MWKProtectionStatus alloc] initWithData:dataEmpty];
    MWKProtectionStatus *protectionEmpty2 = [[MWKProtectionStatus alloc] initWithData:dataEmpty];
    MWKProtectionStatus *protectionObama1 = [[MWKProtectionStatus alloc] initWithData:dataObama];
    MWKProtectionStatus *protectionObama2 = [[MWKProtectionStatus alloc] initWithData:dataObama];
    
    XCTAssertEqualObjects(protectionEmpty1, protectionEmpty1);
    XCTAssertEqualObjects(protectionEmpty1, protectionEmpty2);
    XCTAssertEqualObjects(protectionEmpty2, protectionEmpty1);
    XCTAssertEqualObjects(protectionObama1, protectionObama1);
    XCTAssertEqualObjects(protectionObama1, protectionObama2);
    XCTAssertEqualObjects(protectionObama2, protectionObama1);
    XCTAssertNotEqualObjects(protectionEmpty1, protectionObama1);
    XCTAssertNotEqualObjects(protectionObama1, protectionEmpty1);
}

- (void)testRoundTrip
{
    id dataEmpty = [self loadJSON:@"protection-empty"];
    id dataObama = [self loadJSON:@"protection-obama"];
    MWKProtectionStatus *protectionEmpty1 = [[MWKProtectionStatus alloc] initWithData:dataEmpty];
    MWKProtectionStatus *protectionObama1 = [[MWKProtectionStatus alloc] initWithData:dataObama];

    MWKProtectionStatus *protectionEmpty2 = [[MWKProtectionStatus alloc] initWithData:[protectionEmpty1 dataExport]];
    MWKProtectionStatus *protectionObama2 = [[MWKProtectionStatus alloc] initWithData:[protectionObama1 dataExport]];
    
    XCTAssertEqualObjects(protectionEmpty1, protectionEmpty2);
    XCTAssertEqualObjects(protectionObama1, protectionObama2);
}


@end
