#import <XCTest/XCTest.h>
#import "WMFAsyncTestCase.h"
#import "MWKSiteInfo.h"
#import "MWKSiteInfoFetcher.h"
#import "XCTestCase+WMFLocaleTesting.h"
#import "NSArray+WMFShuffle.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "WMFTestFixtureUtilities.h"
#import <Nocilla/Nocilla.h>

@interface MWKSiteInfoFetcherTests : WMFAsyncTestCase
@property (strong, nonatomic) MWKSiteInfoFetcher *fetcher;
@end

@implementation MWKSiteInfoFetcherTests

- (void)setUp {
    [super setUp];
    self.fetcher = [MWKSiteInfoFetcher new];
    [[LSNocilla sharedInstance] start];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    [super tearDown];
}

- (void)testENWikiFixture {
    [self runSuccessfulCallbackTestWithFixture:@"ENWikiSiteInfo" siteURL:[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"]];
}

- (void)testNOWikiFixture {
    [self runSuccessfulCallbackTestWithFixture:@"NOWikiSiteInfo" siteURL:[NSURL wmf_URLWithDefaultSiteAndlanguage:@"no"]];
}

- (void)runSuccessfulCallbackTestWithFixture:(NSString *)fixture siteURL:(NSURL *)testSiteURL {
    NSString *json = [[self wmf_bundle] wmf_stringFromContentsOfFile:fixture ofType:@"json"];
    NSDictionary *jsonDictionary = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixture];

    NSRegularExpression *anyRequestFromTestSite =
        [NSRegularExpression regularExpressionWithPattern:
                                 [NSString stringWithFormat:@"%@.*", [[NSURL wmf_desktopAPIURLForURL:testSiteURL] absoluteString]]
                                                  options:0
                                                    error:nil];

    stubRequest(@"GET", anyRequestFromTestSite)
        .andReturn(200)
        .withHeaders(@{@"Content-Type": @"application/json"})
        .withBody(json);

    XCTestExpectation *expectation = [self expectationWithDescription:@"response"];

    [self.fetcher fetchSiteInfoForSiteURL:testSiteURL
        completion:^(MWKSiteInfo *_Nonnull result) {
            XCTAssert([result.siteURL isEqual:testSiteURL]);
            XCTAssert([result.mainPageTitleText isEqual:[jsonDictionary valueForKeyPath:@"query.general.mainpage"]]);
            [expectation fulfill];
        }
        failure:^(NSError *_Nonnull error) {
            NSLog(@"%@", [error localizedDescription]);
        }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:nil];
}

- (void)testDesktopFallback {
    NSURL *testSiteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
    NSString *json = [[self wmf_bundle] wmf_stringFromContentsOfFile:@"ENWikiSiteInfo" ofType:@"json"];
    NSDictionary *jsonDictionary = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"ENWikiSiteInfo"];

    NSError *fallbackError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorSecureConnectionFailed userInfo:nil];

    NSRegularExpression *anyRequestFromTestSiteDesktop =
        [NSRegularExpression regularExpressionWithPattern:
                                 [NSString stringWithFormat:@"%@.*", [testSiteURL absoluteString]]
                                                  options:0
                                                    error:nil];

    stubRequest(@"GET", @"https://en.m.wikipedia.org/w/api.php?action=query&format=json&meta=siteinfo&siprop=general")
        .andFailWithError(fallbackError);

    stubRequest(@"GET", anyRequestFromTestSiteDesktop)
        .andReturn(200)
        .withHeaders(@{@"Content-Type": @"application/json"})
        .withBody(json);

    XCTestExpectation *expectation = [self expectationWithDescription:@"response"];

    [self.fetcher fetchSiteInfoForSiteURL:testSiteURL
        completion:^(MWKSiteInfo *_Nonnull result) {
            XCTAssert([result.siteURL isEqual:testSiteURL]);
            XCTAssert([result.mainPageTitleText isEqual:[jsonDictionary valueForKeyPath:@"query.general.mainpage"]]);
            [expectation fulfill];
        }
        failure:^(NSError *_Nonnull error) {
            NSLog(@"%@", [error localizedDescription]);
        }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:nil];
}

#pragma mark - (Flaky) Integration Tests

// Disabled since doing network I/O is slow. Run manually if necessary
#if 0

- (void)testRealFetchOfPopularLocales {
    [self runTestWithLocales:@[@"en_US", @"fr_FR", @"en_GB"]];
}

- (void)testRealFetchOfRandomLocales {
    [self runTestWithLocales:
     [[[NSLocale availableLocaleIdentifiers]
       wmf_shuffledCopy]
      subarrayWithRange:NSMakeRange(0, 100)]];
}

- (void)runTestWithLocales:(NSArray*)localeIdentifiers {
    NSMutableArray* errors = [NSMutableArray new];
    [self wmf_runParallelTestsWithLocales:localeIdentifiers
                                    block:^(NSLocale* locale, XCTestExpectation* expectation) {
        MWKSite* site = [MWKSite siteWithLocale:locale];
        [self.fetcher fetchInfoForSite:site
                               success:^(MWKSiteInfo* info) {
            NSLog(@"Site info for %@: %@", locale.localeIdentifier, info);
            [expectation fulfill];
        }
                               failure:^(NSError* error) {
            @synchronized(errors) {
                [errors addObject:@[locale.localeIdentifier, error]];
            }
            [expectation fulfill];
        }];
    }];
    XCTAssert(errors.count == 0, @"Failed to fetch site info for locales: %@", errors);
}

#endif

@end
