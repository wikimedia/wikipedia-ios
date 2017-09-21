#import <XCTest/XCTest.h>
#import "MWKArticle.h"
#import "MWKSection.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSection_WMFSharingTests : XCTestCase
@property (nonatomic) MWKSection *section;
@end

@implementation MWKSection_WMFSharingTests

- (void)setUp {
    [super setUp];
}

- (void)testSimpleSnippet {
    NSURL *url = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"foo"];
    MWKArticle *article = [[MWKArticle alloc] initWithURL:url dataStore:nil];
    self.section = [[MWKSection alloc] initWithArticle:article
                                                  dict:@{
                                                      @"id": @0,
                                                      @"text": @"<p>Dog (woof (w00t)) [horse] adequately long string historically 40 characters.</p>"
                                                  }];
    assertThat([self.section shareSnippet], is(@"Dog (woof (w00t)) adequately long string historically 40 characters."));
}

- (void)testSimpleSnippetIncludingTable {
    NSURL *url = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"foo"];
    MWKArticle *article = [[MWKArticle alloc] initWithURL:url dataStore:nil];
    self.section = [[MWKSection alloc] initWithArticle:article
                                                  dict:@{
                                                      @"id": @0,
                                                      @"text": @"<table><p>Foo</p></table><p>Dog (woof (w00t)) [horse] adequately long string historically 40 characters.</p>"
                                                  }];
    assertThat([self.section shareSnippet], is(@"Dog (woof (w00t)) adequately long string historically 40 characters."));
}

@end
