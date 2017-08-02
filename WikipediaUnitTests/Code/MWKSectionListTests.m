#import <XCTest/XCTest.h>
#import "MWKArticle.h"
#import "MWKSectionList.h"
#import "MWKSection.h"
#import "MWKDataStore.h"
#import "WMFRandomFileUtilities.h"

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
    self.dataStore = MKTMock([MWKDataStore class]);
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
    assertThat(@(emptySectionList.count), is(equalToInt(0)));
    [MKTVerifyCount(mockArticle.dataStore, MKTNever()) sectionWithId:anything() article:anything()];
}

- (void)testSectionListInitializationExeptionHandling {
    NSURL *url = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"foo"];
    MWKArticle *mockArticle =
        [[MWKArticle alloc] initWithURL:url
                              dataStore:self.dataStore];

    [self addEmptyFolderForSection:0 url:anything() mockDataStore:mockArticle.dataStore];

    // mock an exception, simulating the case where required fields are missing
    [[MKTGiven([self.dataStore sectionWithId:0 article:mockArticle])
        withMatcher:anything()
        forArgument:0]
        willThrow:[NSException exceptionWithName:@"MWKSectionListTestException"
                                          reason:@"to verify initialization behavior"
                                        userInfo:nil]];

    MWKSectionList *emptySectionList = [[MWKSectionList alloc] initWithArticle:mockArticle];
    assertThat(@(emptySectionList.count), is(equalToInt(0)));
}

- (void)addEmptyFolderForSection:(int)sectionId
                             url:(id)urlMatcher
                   mockDataStore:(MWKDataStore *)mockDataStore {
    // create an empty section directory, so that our section list will reach the code path
    // where an exception will be thrown when trying to read the section data
    NSString *randomDirectory = WMFRandomTemporaryPath();
    NSString *randomPath = [randomDirectory stringByAppendingPathComponent:@"sections/0"];
    BOOL didCreateRandomPath = [[NSFileManager defaultManager] createDirectoryAtPath:randomPath
                                                         withIntermediateDirectories:YES
                                                                          attributes:nil
                                                                               error:nil];
    XCTAssert(didCreateRandomPath);
    [MKTGiven([mockDataStore pathForArticleURL:anything()]) willReturn:randomDirectory];
}

@end

#pragma clang diagnostic pop
