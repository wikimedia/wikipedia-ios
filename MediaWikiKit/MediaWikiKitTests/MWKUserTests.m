//
//  MWKUserTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/16/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MWKTestCase.h"

@interface MWKUserTests : MWKTestCase {
    MWKSite *site;
}

@end

@implementation MWKUserTests

- (void)setUp {
    [super setUp];
    site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testImportLoggedIn {
    MWKUser *user = [self loadUser:@"user-loggedin"];

    XCTAssertNotNil(user, @"user is an obj");
    XCTAssert(!user.anonymous, @"user is not anon");
    XCTAssert([user.name length] > 0, @"user has a name");
    XCTAssert([user.gender length] > 0, @"user has a gender field");
}

- (void)testRoundtripLoggedIn {
    MWKUser *user = [self loadUser:@"user-loggedin"];
    NSDictionary *dict = @{@"sample": [user dataExport]};

    MWKUser *user2 = [[MWKUser alloc] initWithSite:site data:dict[@"sample"]];
    XCTAssertEqualObjects(user, user2, @"roundtrip a loggedin user");
}

-(void)testImportAnon {
    MWKUser *user = [self loadUser:@"user-anon"];
    
    XCTAssertNotNil(user, @"user is an obj");
    XCTAssert(user.anonymous, @"user is anon");
    XCTAssertNil(user.name, @"user has no name");
    XCTAssertNil(user.gender, @"user has no gender field");
}

- (MWKUser *)loadUser:(NSString *)name {
    NSDictionary *dict = [self loadJSON:name];
    return [[MWKUser alloc] initWithSite:site data:dict[@"sample"]];
}

@end
