#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKHistoryListCorruptDataTests : XCTestCase
@property(strong, nonatomic) MWKHistoryList *historyList;

@end

@implementation MWKHistoryListCorruptDataTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testPrunesEntriesWithEmptyTitles {
    MWKHistoryList *list = [[MWKHistoryList alloc] initWithEntries:nil];
    [list addPageToHistoryWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Foo"]];
    assertThat(@([list countOfEntries]), is(@1));

    [list addPageToHistoryWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@""]];
    assertThat(@([list countOfEntries]), is(@1));
}

#pragma clang diagnostic pop

@end
