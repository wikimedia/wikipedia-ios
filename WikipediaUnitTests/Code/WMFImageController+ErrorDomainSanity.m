//
//  WMFImageController+ErrorDomainSanity.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/22/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Wikipedia-Swift.h"

@import Nimble;

@interface WMFImageControllerErrorDomainTest : XCTestCase

@end

@implementation WMFImageControllerErrorDomainTest

- (void)testInsanity {
    // these two _should_ be equal, but NSError <-> ErrorType briding & Swift enum handling is wonky in Swift 2.1
    expect([[WMFImageController _castedImageError] domain]).toNot(equal(WMFImageControllerErrorDomain));
}

@end
