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
    [self.articleStore importMobileViewJSON:self.json0];
    [self.articleStore importMobileViewJSON:self.json1];
}

- (void)testLoadNonexistentImage {
    // This should hand us a new image object
    XCTAssertNoThrow([self.articleStore imageWithURL:self.goldenGateImageURL]);
}

- (void)testLoadNonexistentImageData {
    MWKImage *image = [self.articleStore imageWithURL:self.goldenGateImageURL];
    
    // But this data should explode
    XCTAssertThrows([self.articleStore imageDataWithImage:image]);
}

- (void)testLoadExistentImageData {
    NSData *dataSample = [self loadDataFile:@"golden-gate" ofType:@"jpg"];

    MWKImage *image = [self.articleStore importImageURL:self.goldenGateImageURL];
    //MWKImage *image = [self.articleStore imageWithURL:self.goldenGateImageURL];
    XCTAssertNotNil(image);
    XCTAssertNoThrow([self.articleStore importImageData:dataSample image:image mimeType:@"image/jpeg"]);
    
    NSData *dataFromStorage = [self.articleStore imageDataWithImage:image];
    
    XCTAssertEqualObjects(dataSample, dataFromStorage);
}


@end
