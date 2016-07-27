
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSavedPageListCorruptDataTests : XCTestCase

@end

@implementation MWKSavedPageListCorruptDataTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testPrunesEntriesWithEmptyOrAbsentTitles {
    MWKSavedPageList* list = [[MWKSavedPageList alloc] initWithEntries:nil];
    [list addSavedPageWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Foo"]];
    assertThat(@([list countOfEntries]), is(@1));

    [list addSavedPageWithURL:nil];
    assertThat(@([list countOfEntries]), is(@1));

    [list addSavedPageWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@""]];
    assertThat(@([list countOfEntries]), is(@1));
}

#pragma clang diagnostic pop


@end
