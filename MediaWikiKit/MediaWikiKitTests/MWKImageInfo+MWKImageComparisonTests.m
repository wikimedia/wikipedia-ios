//
//  MWKImageInfo+MWKImageComparisonTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImageInfo+MWKImageComparison.h"
#import "MWKImage.h"
#import <XCTest/XCTest.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKImageInfo_MWKImageComparisonTests : XCTestCase

@end

@implementation MWKImageInfo_MWKImageComparisonTests

- (MWKImageInfo*)infoAssociatedWithSourceURL:(NSString*)imageURL {
    return [[MWKImageInfo alloc] initWithCanonicalPageTitle:nil
                                           canonicalFileURL:nil
                                           imageDescription:nil
                                                    license:nil
                                                filePageURL:nil
                                                   imageURL:[NSURL URLWithString:imageURL]
                                              imageThumbURL:nil
                                                      owner:nil
                                                  imageSize:CGSizeZero
                                                  thumbSize:CGSizeZero];
}

- (MWKImage*)imageAssociatedWithSourceURL:(NSString*)imageURL {
    return [[MWKImage alloc] initWithArticle:nil sourceURL:imageURL];
}

- (void)testAssociation {
    MWKImage* image    = [self imageAssociatedWithSourceURL:@"some_file_name.jpg/400px-some_file_name.jpg"];
    MWKImageInfo* info = [self infoAssociatedWithSourceURL:@"some_file_name.jpg/800px-some_file_name.jpg"];
    assertThat(image.infoAssociationValue, is(equalTo(info.imageAssociationValue)));
    XCTAssertTrue([info isAssociatedWithImage:image]);
    XCTAssertTrue([image isAssociatedWithInfo:info]);
}

- (void)testDisassociation {
    MWKImage* image    = [self imageAssociatedWithSourceURL:@"some_file_name.jpg/400px-some_file_name.jpg"];
    MWKImageInfo* info = [self infoAssociatedWithSourceURL:@"other_file_name.jpg/800px-other_file_name.jpg"];
    assertThat([image infoAssociationValue], isNot(equalTo([info imageAssociationValue])));
    XCTAssertFalse([info isAssociatedWithImage:image]);
}

@end
