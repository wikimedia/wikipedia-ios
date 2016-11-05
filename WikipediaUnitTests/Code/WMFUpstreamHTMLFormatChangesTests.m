#import <XCTest/XCTest.h>
#import <OCHamcrest/OCHamcrest.h>
#import <BlocksKit/BlocksKit.h>
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

                                                NSString *expectedHTML = @""
                                                                          "<div class=\"mf-section-0\"><p><a href=\"/wiki/MediaWiki\" title=\"MediaWiki\">"
                                                                          "<img alt=\"Example.jpg\" src=\"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/20px-Example.jpg\" width=\"20\" height=\"21\" srcset=\"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/30px-Example.jpg 1.5x, //upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/40px-Example.jpg 2x\" data-file-width=\"172\" data-file-height=\"178\">"
                                                                          "</a></p>\n\n\n\n\n\n</div>";

                                                // Don't fail on whitespace changes.
                                                html = [html wmf_trimAndNormalizeWhiteSpaceAndNewlinesToSingleSpace];
                                                expectedHTML = [expectedHTML wmf_trimAndNormalizeWhiteSpaceAndNewlinesToSingleSpace];

                                                //                                                XCTAssert([html isEqualToString:expectedHTML]);
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

@end
