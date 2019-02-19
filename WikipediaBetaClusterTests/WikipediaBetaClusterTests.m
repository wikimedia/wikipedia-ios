#import <XCTest/XCTest.h>
@import WMF;

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

@interface WikipediaBetaClusterTests : XCTestCase

@end

@implementation WikipediaBetaClusterTests

- (void)testFormatOfScaledImageTagsHasNotChangedOnBeta {
    // Early notification of any changes to image tag formatting.
    // Changes are staged on wmflabs.org before being deployed to production.
    XCTestExpectation *expectation =
        [self expectationWithDescription:@"Fetch img tag html for a piece of image wikitext. Thus way we can be notified when image tag formatting changes in any way so we can ensure image widening/caching/proxying still work with whatever changes are made."];

    NSString *imgWikitext = @"[[File:Example.jpg|20px|link=MediaWiki]]";
    NSURL *baseURL = [NSURL URLWithString:@"https://en.wikipedia.beta.wmflabs.org/"];
    NSString *urlString = [NSString stringWithFormat:@"https://en.wikipedia.beta.wmflabs.org/w/api.php"
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
                                                XCTAssertNotNil(html, @"Incomplete response from beta cluser");
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
                                        XCTAssertNotNil(sectionsFromBetaCluster, @"Incomplete response from beta cluser");
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

- (BOOL)isTag:(NSString *)tag balancedInString:(NSString *)string {
    string = [string lowercaseString];
    NSArray *a1 = [string componentsSeparatedByString:[@"<" stringByAppendingString:tag]];
    NSArray *a2 = [string componentsSeparatedByString:[@"</" stringByAppendingString:tag]];
    NSLog(@"%@ %ld %ld", tag, a1.count, a2.count);
    return a1.count == a2.count;
}

- (void)testParserDivWrapperHasNotLeakedIntoMobileviewSectionHTMLOnBeta {
    // Early notification of parser divs leaking to mobileview section html output.
    // Changes are staged on wmflabs.org before being deployed to production.

    // Past occurences and the divs they leaked into mobileview output:
    // https://phabricator.wikimedia.org/T186927
    //      <div class="mw-parser-output"
    // https://phabricator.wikimedia.org/T129717
    //      <div class="mw-mobilefrontend-leadsection"

    // If this test fails: identify the div leaking into mobileview output causing the failure and find the
    // upsteam ticket which introduced the change and raise a flag before the change is deployed to production!

    NSURL *betaClusterURL = [NSURL URLWithString:@"https://en.m.wikipedia.beta.wmflabs.org/w/api.php?action=mobileview&format=json&page=Barack_Obama&sections=0&prop=text%7Csections%7Crevision&revision=349208"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetch mobileview section html for a specific revision of an article on beta and confirm text starts with expected string so we can be notified if parser wrapper div leaks into mobileview section html again."];
    NSURLSessionDataTask *dataTask =
        [[NSURLSession sharedSession] dataTaskWithURL:betaClusterURL
                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                        NSArray *sectionsFromBetaCluster = json[@"mobileview"][@"sections"];
                                        if (sectionsFromBetaCluster.count == 0) {
                                            XCTFail(@"Incomplete response from beta cluser");
                                            [expectation fulfill];
                                            return;
                                        }
                                        NSDictionary *firstSectionFromBetaCluster = sectionsFromBetaCluster[0];
                                        NSString *firstSectionTextFromBetaCluster = firstSectionFromBetaCluster[@"text"];
                                        XCTAssertTrue([firstSectionTextFromBetaCluster hasPrefix:@"<p>hello there"], @"\n\nSome parser HTML may have leaked into mobileview output. This test which just failed is an early warning sign that something has been staged to the beta cluster which may cause a parser div to leak into mobileview output if it is deployed to production. Don't ignore this failure!\n\n");

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

@end
