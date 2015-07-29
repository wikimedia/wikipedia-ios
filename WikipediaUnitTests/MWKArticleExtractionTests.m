//
//  MWKArticle+WMFSharingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "SessionSingleton.h"
#import "WMFTestFixtureUtilities.h"
#import "MWKTitle.h"
#import "MWKSite.h"
#import "MWKArticle+WMFSharing.h"
#import "MWKDataStore+TemporaryDataStore.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKArticleExtractionTests : XCTestCase
@property (nonatomic) MWKArticle* article;
@end

@implementation MWKArticleExtractionTests

- (void)testMainPage {
    self.article =
        [[MWKArticle alloc] initWithTitle:[MWKTitle titleWithString:@"Main Page" site:[MWKSite siteWithCurrentLocale]]
                                dataStore:nil];

    NSDictionary* mainPageMobileView = [[[self wmf_bundle]
                                         wmf_jsonFromContentsOfFile:@"MainPageMobileView"]
                                        objectForKey:@"mobileview"];

    [self.article importMobileViewJSON:mainPageMobileView];

    NSAssert([self.article isMain], @"supposed to be testing main pages!");

    assertThat(self.article.shareSnippet, is(@"Gary Cooper was an American film actor known for his natural, authentic, and understated acting style. He was a movie star from the end of the silent film era through the end of the golden age of Classical Hollywood. Cooper began his career as a film extra and stunt rider and soon established himself as a Western hero in films such as The Virginian. He played the lead in adventure films and dramas such as A Farewell to Arms and The Lives of a Bengal Lancer, and extended his range of performances to include roles in most major film genres. He portrayed champions of the common man in films such as Mr. Deeds Goes to Town, Meet John Doe, Sergeant York, The Pride of the Yankees, and For Whom the Bell Tolls. In his later years, he delivered award-winning performances in High Noon and Friendly Persuasion. Cooper received three Academy Awards and appeared on the Motion Picture Herald exhibitors poll of top ten film personalities every year from 1936 to 1958. His screen persona embodied the American folk hero. Ongoing: Nepal earthquake – Yemeni Civil WarRecent deaths: Ruth Rendell – Maya Plisetskaya"));
}

- (void)testExpectedSnippetForObamaArticle {
    NSDictionary* obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"];
    MWKTitle* dummyTitle              =
        [MWKTitle titleWithString:@"foo" site:[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"]];
    self.article = [[MWKArticle alloc] initWithTitle:dummyTitle dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    assertThat(self.article.shareSnippet, is(@"Barack Hussein Obama II is the 44th and current President of the United States, and the first African American to hold the office. Born in Honolulu, Hawaii, Obama is a graduate of Columbia University and Harvard Law School, where he served as president of the Harvard Law Review. He was a community organizer in Chicago before earning his law degree. He worked as a civil rights attorney and taught constitutional law at the University of Chicago Law School from 1992 to 2004. He served three terms representing the 13th District in the Illinois Senate from 1997 to 2004, running unsuccessfully for the United States House of Representatives in 2000."));
}

@end
