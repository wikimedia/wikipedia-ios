//
//  MWKLanguageLinkResponseSerializerTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKLanguageLinkResponseSerializer.h"

@interface MWKLanguageLinkResponseSerializerTests : XCTestCase

@end

@implementation MWKLanguageLinkResponseSerializerTests

- (void)testNullHandling {
    MWKLanguageLinkResponseSerializer *serializer = [MWKLanguageLinkResponseSerializer serializer];
    NSDictionary *badResponse = @{
        @"query" : @{
            @"pages" : @{
                @"fakePageId" : @{} //< empty language link object
            }
        }
    };
    NSData *badResponseData = [NSJSONSerialization dataWithJSONObject:badResponse options:0 error:nil];
    id serializedResponse = [serializer responseObjectForResponse:nil data:badResponseData error:nil];
    XCTAssertEqualObjects(serializedResponse, (@{}));
}

@end
