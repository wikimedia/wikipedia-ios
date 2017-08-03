#import <XCTest/XCTest.h>
#import "WMFAsyncTestCase.h"
#import "MWKLanguageLinkFetcher.h"
#import "WMFNetworkUtilities.h"
#import <AFNetworking/AFHTTPSessionManager.h>

@interface MWKLanguageLinkFetcherTests : WMFAsyncTestCase
@property (nonatomic, strong) MWKLanguageLinkFetcher *fetcher;
@end

@implementation MWKLanguageLinkFetcherTests

- (void)setUp {
    self.fetcher = [[MWKLanguageLinkFetcher alloc] initWithManager:[[QueuesSingleton sharedInstance] languageLinksFetcher]
                                                          delegate:nil];
    [super setUp];
}

- (void)testFetchingNilTitle {
    PushExpectation();
    [self.fetcher fetchLanguageLinksForArticleURL:nil
        success:^(NSArray *langLinks) {
            XCTFail(@"Expected nil title to result in failure.");
        }
        failure:^(NSError *error) {
            XCTAssertEqual(error.code, WMFNetworkingError_InvalidParameters);
            [self popExpectationAfter:nil];
        }];
    WaitForExpectations();
}

- (void)testFetchingEmptyTitle {
    NSURL *url = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@""];

    PushExpectation();
    [self.fetcher fetchLanguageLinksForArticleURL:url
        success:^(NSArray *langLinks) {
            XCTFail(@"Expected empty title to result in failure.");
        }
        failure:^(NSError *error) {
            XCTAssertEqual(error.code, WMFNetworkingError_InvalidParameters);
            [self popExpectationAfter:nil];
        }];
    WaitForExpectations();
}

@end
