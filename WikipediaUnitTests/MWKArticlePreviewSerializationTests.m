//
//  MWKArticlePreviewSerializationTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/12/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MWKArticlePreview.h"

@interface MWKArticlePreviewSerializationTests : XCTestCase

@end

@implementation MWKArticlePreviewSerializationTests

- (void)testSerializingFromFixture {
    NSDictionary* previewJSON =
        [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"mobileview-preview"][@"mobileview"];
    NSError* error;
    MWKArticlePreview* __unused preview = [MTLJSONAdapter modelOfClass:[MWKArticlePreview class]
                                                    fromJSONDictionary:previewJSON
                                                                 error:&error];
    XCTAssertNil(error,
                 @"Failed to deserialize preview from fixture %@ due to error %@",
                 previewJSON,
                 error);
}

@end
