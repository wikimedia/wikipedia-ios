//
//  MWKImageStorageTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MWKArticleStoreTestCase.h"

@interface MWKImageStorageTests : MWKArticleStoreTestCase

@property NSString *goldenGateImageURL;

@end

@implementation MWKImageStorageTests

- (void)setUp {
    [super setUp];
    self.goldenGateImageURL = @"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Golden_Gate_Bridge%2C_SF_%28cropped%29.jpg/500px-Golden_Gate_Bridge%2C_SF_%28cropped%29.jpg";
    [self.article importMobileViewJSON:self.json0[@"mobileview"]];
    [self.article importMobileViewJSON:self.json1[@"mobileview"]];
}

- (void)testLoadNonexistentImage {
    // This should hand us a new image object
    XCTAssertNotNil([self.article importImageURL:self.goldenGateImageURL sectionId:0]);
}

- (void)testLoadNonexistentImageData {
    MWKImage *image = [self.article importImageURL:self.goldenGateImageURL sectionId:0];
    XCTAssertNotNil(image);
    
    // But this data should explode
    NSData *data = [self.article.dataStore imageDataWithImage:image];
    XCTAssertNil(data);
}

- (void)testLoadExistentImageData {
    NSData *dataSample = [self loadDataFile:@"golden-gate" ofType:@"jpg"];

    MWKImage *image = [self.article importImageURL:self.goldenGateImageURL sectionId:0];
    //MWKImage *image = [self.articleStore imageWithURL:self.goldenGateImageURL];
    XCTAssertNotNil(image);
    XCTAssertNoThrow([self.article importImageData:dataSample image:image mimeType:@"image/jpeg"]);
    
    NSData *dataFromStorage = [self.article.dataStore imageDataWithImage:image];
    
    XCTAssertEqualObjects(dataSample, dataFromStorage);
}


@end
