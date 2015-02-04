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

- (MWKImageInfo*)infoAssociatedWithFilename:(NSString*)filename
{
    return [[MWKImageInfo alloc] initWithCanonicalPageTitle:[@"File:" stringByAppendingString:filename]
                                           canonicalFileURL:nil
                                           imageDescription:nil
                                                    license:nil
                                                filePageURL:nil
                                                   imageURL:nil
                                                      owner:nil];
}

- (MWKImage*)imageAssociatedWithFilename:(NSString*)filename
{
    NSString *testFilenameForURL = [filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [[MWKImage alloc] initWithArticle:nil
                                   sourceURL:[NSString stringWithFormat:@"foo/%@/440px-%@",
                                                                        testFilenameForURL, testFilenameForURL]];
}

- (void)testAssociation
{
    NSString *testFilename = @"some-file name";
    MWKImage *image = [self imageAssociatedWithFilename:testFilename];
    MWKImageInfo *info = [self infoAssociatedWithFilename:testFilename];
    assertThat(image.infoAssociationValue,
               is(allOf(equalTo(info.imageAssociationValue),
                        equalTo([info valueForKeyPath:MWKImageAssociationKeyPath]),
                        equalTo([image valueForKeyPath:MWKImageAssociationKeyPath]), nil)));
    XCTAssertTrue([info isAssociatedWithImage:image]);
    XCTAssertTrue([image isAssociatedWithInfo:info]);
}

- (void)testDisassociation
{
    MWKImage *image = [self imageAssociatedWithFilename:@"some-file name"];
    MWKImageInfo *info = [self infoAssociatedWithFilename:@"other file name"];
    assertThat([image valueForKeyPath:MWKImageAssociationKeyPath],
               isNot([info valueForKeyPath:MWKImageAssociationKeyPath]));
    XCTAssertFalse([info isAssociatedWithImage:image]);
}

@end
