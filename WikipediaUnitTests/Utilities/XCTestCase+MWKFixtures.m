//
//  XCTestCase+MWKFixtures.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "XCTestCase+MWKFixtures.h"
#import "XCTestCase+WMFBundleConvenience.h"
#import "MWKArticle.h"
#import "NSBundle+TestAssets.h"
#import "MWKTitle.h"

@implementation XCTestCase (MWKFixtures)

- (MWKArticle*)articleFixtureNamed:(NSString*)fixtureName
                         withTitle:(id)titleOrString
                         dataStore:(MWKDataStore*)dataStore {
    NSDictionary* mobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName];
    MWKTitle* title              = [titleOrString isKindOfClass:[NSString class]] ?
                                   (MWKTitle*)titleOrString
                                   : [MWKTitle titleWithString:titleOrString site:[MWKSite siteWithDomain:@"en" language:@"wikipedia.org"]];
    return [[MWKArticle alloc] initWithTitle:title
                                   dataStore:dataStore
                                        dict:mobileViewJSON[@"mobileview"]];
}

@end
