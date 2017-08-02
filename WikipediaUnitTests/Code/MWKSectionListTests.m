#import <XCTest/XCTest.h>
#import "MWKArticle.h"
#import "MWKSectionList.h"
#import "MWKSection.h"
#import "MWKDataStore.h"
#import "WMFRandomFileUtilities.h"
#import "MWKDataStore+TemporaryDataStore.h"

// suppress warning about passing "anything()" to "sectionWithId:"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wint-conversion"

@interface MWKSectionListTests : XCTestCase
/// Need a ref to the data store, since it's not retained by any entities.
@property (nonatomic, strong) MWKDataStore *dataStore;
@end

@implementation MWKSectionListTests

- (void)setUp {
    [super setUp];
    self.dataStore = [MWKDataStore temporaryDataStore];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCreatingSectionListWithNoData {
    NSURL *url = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"foo"];
    MWKArticle *mockArticle =
        [[MWKArticle alloc] initWithURL:url
                              dataStore:self.dataStore];
    MWKSectionList *emptySectionList = [[MWKSectionList alloc] initWithArticle:mockArticle];
    XCTAssertEqual(emptySectionList.count, 0);
}

@end

#pragma clang diagnostic pop
