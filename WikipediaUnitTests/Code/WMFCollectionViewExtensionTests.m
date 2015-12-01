//
//  WMFNetworkUtilitiesTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "UICollectionView+WMFExtensions.h"

@interface WMFCollectionViewExtensionTests : XCTestCase<UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView* collectionView;
@property (nonatomic, strong) NSArray* data;

@end

@implementation WMFCollectionViewExtensionTests


- (void)setUp {
    [super setUp];

    self.collectionView            = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout new]];
    self.collectionView.dataSource = self;

    self.data = @[@[@"0-0", @"0-1", @"0-2"],
                  @[@"1-0", @"1-1"],
                  @[@"2-0"]];
}

- (void)tearDown {
    self.collectionView = nil;
    self.data           = nil;
    [super tearDown];
}

- (void)testNext {
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    NSIndexPath* next      = [self.collectionView wmf_indexPathAfterIndexPath:indexPath];
    XCTAssertEqual(next, [NSIndexPath indexPathForItem:1 inSection:0]);
}

- (void)testNextLast {
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:0 inSection:2];
    NSIndexPath* next      = [self.collectionView wmf_indexPathAfterIndexPath:indexPath];
    XCTAssertEqual(next, nil);
}

- (void)testNextNewSection {
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:2 inSection:0];
    NSIndexPath* next      = [self.collectionView wmf_indexPathAfterIndexPath:indexPath];
    XCTAssertEqual(next, [NSIndexPath indexPathForItem:0 inSection:1]);
}

- (void)testPrevious {
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
    NSIndexPath* previous  = [self.collectionView wmf_indexPathBeforeIndexPath:indexPath];
    XCTAssertEqual(previous, [NSIndexPath indexPathForItem:0 inSection:0]);
}

- (void)testPreviousNewSection {
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:0 inSection:1];
    NSIndexPath* previous  = [self.collectionView wmf_indexPathBeforeIndexPath:indexPath];
    XCTAssertEqual(previous, [NSIndexPath indexPathForItem:2 inSection:0]);
}

- (void)testPreviousFirst {
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    NSIndexPath* previous  = [self.collectionView wmf_indexPathBeforeIndexPath:indexPath];
    XCTAssertEqual(previous, nil);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return [self.data count];
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.data[section] count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [[UICollectionViewCell alloc] initWithFrame:CGRectZero];
}

@end
