//
//  MWKImageListTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <BlocksKit/BlocksKit.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#import "MWKArticle.h"
#import "MWKSection.h"
#import "MWKSectionList.h"
#import "MWKDataStore.h"
#import "MWKImageList.h"

@interface MWKImageListTests : XCTestCase
@property (nonatomic, strong) NSString* tempDataStoreDir;
@end

@implementation MWKImageListTests

- (void)setUp {
    [super setUp];
    _tempDataStoreDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
}

- (void)tearDown {
    [super tearDown];
    [[NSFileManager defaultManager] removeItemAtPath:_tempDataStoreDir error:nil];
}

- (void)testUniqueLargestVariants {
    MWKDataStore* tmpDataStore = [[MWKDataStore alloc] initWithBasePath:self.tempDataStoreDir];

    // create article w/ mock section to prevent crashing due to image import side effects
    MWKArticle* article = [[MWKArticle alloc] initWithTitle:nil dataStore:tmpDataStore];
    [article.sections setSections:mock([MWKSection class])];

    NSArray* dummySourceURLs = [@[@"10px-a.jpg", @"10px-b.jpg", @"100px-a.jpg", @"10px-c.jpg"] bk_map :^id (id obj) {
        return [MWKDataStoreValidImageSitePrefix stringByAppendingString:obj];
    }];

    [dummySourceURLs bk_each:^(NSString* sourceURL) {
        [article importImageURL:sourceURL sectionId:0];
    }];

    assertThat([[article.images uniqueLargestVariants] valueForKeyPath:@"sourceURL.lastPathComponent"],
               is(equalTo(@[@"100px-a.jpg", @"10px-b.jpg", @"10px-c.jpg"])));
}

@end
