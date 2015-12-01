//
//  MWKSectionListTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 4/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKArticle.h"
#import "MWKSectionList.h"
#import "MWKSection.h"
#import "MWKDataStore.h"
#import "WMFRandomFileUtilities.h"
#import "MWKTitle.h"
#import "MWKSite.h"

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

// suppress warning about passing "anything()" to "sectionWithId:"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wint-conversion"

@interface MWKSectionListTests : XCTestCase
/// Need a ref to the data store, since it's not retained by any entities.
@property (nonatomic, strong) MWKDataStore* dataStore;
@end

@implementation MWKSectionListTests

- (void)setUp {
    [super setUp];
    self.dataStore = MKTMock([MWKDataStore class]);
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCreatingSectionListWithNoData {
    MWKTitle* title         = [[MWKSite siteWithCurrentLocale] titleWithString:@"foo"];
    MWKArticle* mockArticle =
        [[MWKArticle alloc] initWithTitle:title dataStore:self.dataStore];
    MWKSectionList* emptySectionList = [[MWKSectionList alloc] initWithArticle:mockArticle];
    assertThat(@(emptySectionList.count), is(equalToInt(0)));
    [MKTVerifyCount(mockArticle.dataStore, MKTNever()) sectionWithId:anything() article:anything()];
}

- (void)testSectionListInitializationExeptionHandling {
    MWKTitle* title         = [[MWKSite siteWithCurrentLocale] titleWithString:@"foo"];
    MWKArticle* mockArticle =
        [[MWKArticle alloc] initWithTitle:title dataStore:self.dataStore];

    [self addEmptyFolderForSection:0 title:anything() mockDataStore:mockArticle.dataStore];

    // mock an exception, simulating the case where required fields are missing
    [[MKTGiven([self.dataStore sectionWithId:0 article:mockArticle])
      withMatcher:anything() forArgument:0]
     willThrow:[NSException exceptionWithName:@"MWKSectionListTestException"
                                       reason:@"to verify initialization behavior"
                                     userInfo:nil]];

    MWKSectionList* emptySectionList = [[MWKSectionList alloc] initWithArticle:mockArticle];
    assertThat(@(emptySectionList.count), is(equalToInt(0)));
}

- (void)addEmptyFolderForSection:(int)sectionId
                           title:(id)titleMatcher
                   mockDataStore:(MWKDataStore*)mockDataStore {
    // create an empty section directory, so that our section list will reach the code path
    // where an exception will be thrown when trying to read the section data
    NSString* randomDirectory = WMFRandomTemporaryPath();
    NSString* randomPath      = [randomDirectory stringByAppendingPathComponent:@"sections/0"];
    BOOL didCreateRandomPath  = [[NSFileManager defaultManager] createDirectoryAtPath:randomPath
                                                          withIntermediateDirectories:YES
                                                                           attributes:nil
                                                                                error:nil];
    NSParameterAssert(didCreateRandomPath);
    [MKTGiven([mockDataStore pathForTitle:anything()]) willReturn:randomDirectory];
}

@end

#pragma clang diagnostic pop
