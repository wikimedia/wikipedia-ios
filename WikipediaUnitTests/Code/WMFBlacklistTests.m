
#import <XCTest/XCTest.h>
#import "WMFAsyncTestCase.h"
#import "WMFRelatedSectionBlackList.h"

@interface WMFRelatedSectionBlackList (WMFTesting)

+ (instancetype)loadFromDisk;

@end


@interface WMFBlacklistTests : WMFAsyncTestCase

@end

@implementation WMFBlacklistTests

- (void)tearDown {
    WMFRelatedSectionBlackList* bl = [[WMFRelatedSectionBlackList alloc] init];
    [bl removeAllEntries];
    [bl save];
    [super tearDown];
}

- (void)testPersistsToDisk {
    PushExpectation();
    NSURL* url                = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"some-title"];
    WMFRelatedSectionBlackList* bl = [[WMFRelatedSectionBlackList alloc] init];
    [bl addBlackListArticleURL:url];
    [bl save].then(^(){
        [self popExpectationAfter:nil];
    }).catch(^(NSError* error){
        XCTFail(@"Error callback erroneously called with error %@", error);
    });
    WaitForExpectations();

    bl = [WMFRelatedSectionBlackList loadFromDisk];
    NSURL* first = [[bl entries] firstObject];

    XCTAssertTrue([url isEqual:first],
                  @"Title persisted should be equal to the title loaded from disk");
}

@end
