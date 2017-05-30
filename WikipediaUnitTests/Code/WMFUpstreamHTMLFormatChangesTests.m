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

- (void)testForUnpairedOpeningAndClosingDivsAndSpansInMobileviewSectionHTMLOnBeta {
    // Early notification of unequal number of opening and closing div/span tags in mobileview
    // section html output. Changes are staged on wmflabs.org before being deployed to production.
    
    // We had a really bad change make it to production which introduced an opening DIV tag
    // *without* a matching closing DIV tag to the first section HMTL for every mobileview
    // request: https://phabricator.wikimedia.org/T165115
    
    // This test makes a mobileview request to the beta cluster for a specific revision of
    // an article and ensures each div and span has both an opener and a closer.
    //
    // If this test fails, find the upsteam ticket which introduced the change ASAP and raise
    // a flag before the change is deployed to production!
    
    NSURL *betaClusterURL = [NSURL URLWithString:@"https://en.m.wikipedia.beta.wmflabs.org/w/api.php?action=mobileview&format=json&page=Barack_Obama&sections=all&prop=text%7Csections%7Crevision&revision=349208"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetch mobileview section html for a specific revision of an article on beta and ensure each div and span has both an opener and a closer."];
    NSURLSessionDataTask *dataTask =
    [[NSURLSession sharedSession] dataTaskWithURL:betaClusterURL
                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                    NSArray *sectionsFromBetaCluster = json[@"mobileview"][@"sections"];
                                    
                                    for (NSInteger i = 0; i < sectionsFromBetaCluster.count; i++) {
                                        NSDictionary *sectionFromBetaCluster = sectionsFromBetaCluster[i];
                                        NSString *sectionTextFromBetaCluster = sectionFromBetaCluster[@"text"];
                                        
                                        BOOL divsAreBalanced = [self isTag:@"div" balancedInString:sectionTextFromBetaCluster];
                                        XCTAssert(divsAreBalanced, @"Something staged on the beta cluster has introduced an unclosed (or unopened) %@! See test comments for details. Track this down ASAP because this affects the app in a bad way - see T165115 for similar incident.", @"div");

                                        BOOL spansAreBalanced = [self isTag:@"span" balancedInString:sectionTextFromBetaCluster];
                                        XCTAssert(spansAreBalanced, @"Something staged on the beta cluster has introduced an unclosed (or unopened) %@! See test comments for details. Track this down ASAP because this affects the app in a bad way - see T165115 for similar incident.", @"span");
                                    }
                                    
                                    [expectation fulfill];
                                    
                                }];
    [dataTask resume];
    
    [self waitForExpectationsWithTimeout:120.0
                                 handler:^(NSError *error) {
                                     if (error) {
                                         NSLog(@"Timeout Error: %@", error);
                                     }
                                 }];
}

- (BOOL)isTag:(NSString*)tag balancedInString:(NSString*)string {
    string = [string lowercaseString];
    NSArray *a1 = [string componentsSeparatedByString:[@"<" stringByAppendingString:tag]];
    NSArray *a2 = [string componentsSeparatedByString:[@"</" stringByAppendingString:tag]];
    NSLog(@"%@ %ld %ld", tag, a1.count, a2.count);
    return a1.count == a2.count;
}

@end
