//
//  WMFImageURLParsingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFImageURLParsing.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFImageURLParsingTests : XCTestCase

@end

@implementation WMFImageURLParsingTests

- (void)testNoPrefixExample {
    NSString* testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURL),
               is(equalTo(@"Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg")));
}

- (void)testImageWithOneExtensionExample {
    NSString* testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/640px-Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURL),
               is(equalTo(@"Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg")));
}

- (void)testImageWithTwoExtensionsExample {
    NSString* testURL = @"http://upload.wikimedia.org/wikipedia/commons/thumb/3/34/Access_to_drinking_water_in_third_world.svg/320px-Access_to_drinking_water_in_third_world.svg.png";
    assertThat(WMFParseImageNameFromSourceURL(testURL),
               is(equalTo(@"Access_to_drinking_water_in_third_world.svg")));
}

- (void)testImageWithPeriodInFileNameExample {
    NSString* testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg/360px-Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURL),
               is(equalTo(@"Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg")));
}

- (void)testImageWithMultiplePeriodsInFilename {
    NSString* testURLString =
        @"//upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Blacksmith%27s_tools_-_geograph.org.uk_-_1483374.jpg/440px-Blacksmith%27s_tools_-_geograph.org.uk_-_1483374.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURLString),
               is(equalTo(@"Blacksmith%27s_tools_-_geograph.org.uk_-_1483374.jpg")));
}

- (void)testPrefixFromNoPrefixFileName {
    NSString* testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";

    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

- (void)testPrefixFromImageWithOneExtensionExample {
    NSString* testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/640px-Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), 640);
}

- (void)testPrefixFromUrlWithoutImageFileLastPathComponent {
    NSString* testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

- (void)testPrefixFromZeroWidthImage {
    NSString* testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/0px-Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

- (void)testPrefixFromEmptyStringUrl {
    NSString* testURL = @"";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

- (void)testPrefixFromNilUrl {
    NSString* testURL = nil;
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

@end
