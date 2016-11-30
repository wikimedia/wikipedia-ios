#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"

@interface MWKSavedPageListCorruptDataTests : XCTestCase

@end

@implementation MWKSavedPageListCorruptDataTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testPrunesEntriesWithEmptyOrAbsentTitles {
    MWKDataStore *dataStore = [MWKDataStore temporaryDataStore];
    MWKSavedPageList *list = [[MWKSavedPageList alloc] initWithDataStore:dataStore];
    [list addSavedPageWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Foo"]];
    [list addSavedPageWithURL:nil];
    @try {
        [list addSavedPageWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@""]];
    } @catch (NSException *exception) {
        
    }
    XCTAssertEqual([list numberOfItems], 1);
}

#pragma clang diagnostic pop

@end
