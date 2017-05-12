#import <XCTest/XCTest.h>
#import <OCHamcrest/OCHamcrest.h>
#import "MWKTestCase.h"

@interface NSString (WMFNormalizeWhitespace)

- (NSString *)wmf_trimAndNormalizeWhiteSpaceAndNewlinesToSingleSpace;

@end

@implementation NSString (WMFNormalizeWhitespace)

- (NSString *)wmf_trimAndNormalizeWhiteSpaceAndNewlinesToSingleSpace {
    NSString *result = [self stringByReplacingOccurrencesOfString:@"\\s+"
                                                       withString:@" "
                                                          options:NSRegularExpressionSearch
                                                            range:NSMakeRange(0, self.length)];
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end

@interface WMFUpstreamHTMLFormatChangesTests : MWKTestCase
@end

@implementation WMFUpstreamHTMLFormatChangesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFormatOfScaledImageTagsHasNotChangedOnBeta {
    // Early notification of any changes to image tag formatting.
    // Changes are staged on wmflabs.org before being deployed to production.
    XCTestExpectation *expectation =
        [self expectationWithDescription:@"Fetch img tag html for a piece of image wikitext. Thus way we can be notified when image tag formatting changes in any way so we can ensure image widening/caching/proxying still work with whatever changes are made."];

    NSString *imgWikitext = @"[[File:Example.jpg|20px|link=MediaWiki]]";
    NSURL *baseURL = [NSURL URLWithString:@"http://en.wikipedia.beta.wmflabs.org/"];
    NSString *urlString = [NSString stringWithFormat:@"http://en.wikipedia.beta.wmflabs.org/w/api.php"
                                                      "?action=parse"
                                                      "&format=json"
                                                      "&text=%@"
                                                      "&prop=%@"
                                                      "&disableeditsection=1"
                                                      "&mobileformat=1",
                                                     [imgWikitext stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                                                     [@"text|images" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:urlString]
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                                NSString *html = json[@"parse"][@"text"][@"*"];
                                                [html wmf_enumerateHTMLImageTagContentsWithHandler:^(NSString *_Nonnull imageTagContents, NSRange range) {
                                                    WMFImageTag *tag = [[WMFImageTag alloc] initWithImageTagContents:imageTagContents baseURL:baseURL];

                                                    XCTAssertEqualObjects(tag.width, @(20));
                                                    XCTAssertEqualObjects(tag.height, @(21));
                                                    XCTAssertEqualObjects(tag.dataFileWidth, @(172));
                                                    XCTAssertEqualObjects(tag.dataFileHeight, @(178));
                                                    XCTAssertTrue([tag.src wmf_isEqualToStringIgnoringCase:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/20px-Example.jpg"]);

                                                    // alt has never been parsed - should it be?
                                                    //XCTAssertEqualObjects(tag.alt, @"Example.jpg");

                                                }];
                                                [expectation fulfill];

                                            }];
    [dataTask resume];

    [self waitForExpectationsWithTimeout:15.0
                                 handler:^(NSError *error) {
                                     if (error) {
                                         NSLog(@"Timeout Error: %@", error);
                                     }
                                 }];
}

- (void)testFormatOfMobileviewSectionHTMLNotChangedOnBeta {
    NSArray *sectionsFromFixtureFile = [self loadJSON:@"obama-beta-cluster-revision-349208"][@"mobileview"][@"sections"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for article fetch"];
    NSURL *betaClusterURL = [NSURL URLWithString:@"https://en.m.wikipedia.beta.wmflabs.org/w/api.php?action=mobileview&format=json&page=Barack_Obama&sections=all&prop=text%7Csections%7Crevision&revision=349208"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:betaClusterURL
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                                NSArray *sectionsFromBetaCluster = json[@"mobileview"][@"sections"];
                                                
                                                XCTAssertEqualObjects(@(sectionsFromBetaCluster.count), @(sectionsFromFixtureFile.count), @"Section count mismatch! See test for details.");
                                                
                                                for (NSInteger i = 0; i < sectionsFromBetaCluster.count; i++) {
                                                    NSDictionary *sectionFromFixtureFile = sectionsFromFixtureFile[i];
                                                    NSDictionary *sectionFromBetaCluster = sectionsFromBetaCluster[i];
                                                    NSString *sectionTextFromFixture = sectionFromFixtureFile[@"text"];
                                                    NSString *sectionTextFromBetaCluster = sectionFromBetaCluster[@"text"];
                                                    XCTAssertTrue([sectionTextFromFixture isEqualToString:sectionTextFromBetaCluster], @"Something staged on the beta cluster appears to have changed something about the structure of the section HTML delivered by mobileview. (Background: We had a really bad change make it to production which introduced an opening DIV tag *without* a matching closing DIV tag to the first section HMTL for every mobileview request: https://phabricator.wikimedia.org/T165115). This test which just failed is an early warning sign that something has been staged to the beta cluster which may be similarly problematic if it is deployed to production. Don't ignore this test if it fails! This test makes a mobileview request to the beta cluster for a specific revision of an article and compares the fetched section html with that from a fixture file containing JSON from the same request. A failing test indicates mobileview output has diverged from what it output at the time we created the fixture file. If the diff (between 'sectionTextFromFixture' and 'sectionTextFromBetaCluster') is examined and the change is acceptable you'll need to regenerate the fixture file using the same url the test uses to make the api request. (No need to change the url or the fixture file name - can keep testing against this old revision.) If the diff is examined and the change is problematic find the upsteam ticket which introduced the change and raise a flag before the change is deployed to production! \n\n\n 'sectionTextFromFixture' was:\n\n%@ \n\n\n 'sectionTextFromBetaCluster' was:\n\n%@ \n\n\n", sectionTextFromFixture, sectionTextFromBetaCluster);
                                                }
                                                
                                                [expectation fulfill];
                                                
                                            }];
    [dataTask resume];
    
    [self waitForExpectationsWithTimeout:20.0
                                 handler:^(NSError *error) {
                                     if (error) {
                                         NSLog(@"Timeout Error: %@", error);
                                     }
                                 }];
}

@end
