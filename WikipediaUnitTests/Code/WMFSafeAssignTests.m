//
//  WMFSafeAssignTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFOutParamUtils.h"

@interface WMFSafeAssignTests : XCTestCase

@end

@implementation WMFSafeAssignTests

- (void)assignValue:(id)value toOutParam:(NSObject **)outObj {
    WMFSafeAssign(outObj, value);
}

- (void)testAssigningNilToNil {
    XCTAssertNoThrow([self assignValue:nil toOutParam:nil]);
}

- (void)testAssigningValueToRef {
    id outValue;
    XCTAssertNoThrow([self assignValue:@1 toOutParam:&outValue]);
    XCTAssertEqualObjects(@1, outValue);
}

- (void)testAssigningValueToNil {
    XCTAssertNoThrow([self assignValue:@1 toOutParam:nil]);
}

@end
