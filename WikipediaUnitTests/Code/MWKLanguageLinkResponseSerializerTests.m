#import <XCTest/XCTest.h>
#import "MWKLanguageLinkResponseSerializer.h"

@interface MWKLanguageLinkResponseSerializerTests : XCTestCase

@end

@implementation MWKLanguageLinkResponseSerializerTests

- (void)testNullHandling {
    MWKLanguageLinkResponseSerializer *serializer = [MWKLanguageLinkResponseSerializer serializer];
    NSDictionary *badResponse = @{
        @"query": @{
            @"pages": @{
                @"fakePageId": @{} //< empty language link object
            }
        }
    };
    NSData *badResponseData = [NSJSONSerialization dataWithJSONObject:badResponse options:0 error:nil];
    id serializedResponse = [serializer responseObjectForResponse:nil data:badResponseData error:nil];
    XCTAssertEqualObjects(serializedResponse, (@{}));
}

@end
