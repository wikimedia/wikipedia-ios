//
//  XCTestCase+MWKFixtures.h
//  Wikipedia
//
//  Created by Brian Gerstle on 5/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>

@class MWKArticle;
@class MWKTitle;
@class MWKDataStore;

@interface XCTestCase (MWKFixtures)

- (MWKArticle*)articleFixtureNamed:(NSString*)fixtureName
                         withTitle:(id)titleOrString
                         dataStore:(MWKDataStore*)dataStore;

@end
