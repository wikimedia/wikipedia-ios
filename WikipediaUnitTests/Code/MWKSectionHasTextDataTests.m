#import "XCTestCase+MWKFixtures.h"
#import <XCTest/XCTest.h>
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFTestFixtureUtilities.h"
#import "SessionSingleton.h"

@interface MWKSectionHasTextDataTests : XCTestCase
@property SessionSingleton *session;
@end

@implementation MWKSectionHasTextDataTests

- (void)setUp {
    [super setUp];
    self.session = [[SessionSingleton alloc] initWithDataStore:[MWKDataStore temporaryDataStore]];
}

- (void)tearDown {
    [self.session.dataStore removeFolderAtBasePath];
    [super tearDown];
}

- (MWKArticle *)getTestingArticle {
    NSURL *url = [NSURL wmf_URLWithDomain:@"wikipedia.org" language:@"en" title:@"Barack Obama" fragment:nil];
    MWKArticle *article = [self articleWithMobileViewJSONFixture:@"Obama" withURL:url dataStore:self.session.dataStore];
    [article save:nil];
    return article;
}

- (void)testHasTextDataMethodReturnsYESforZeroLengthSectionHTML {
    // Ensure at least one section of article has zero length section html.
    MWKArticle *article = [self getTestingArticle];
    BOOL atLeastOneZeroLengthSection = NO;
    for (MWKSection *section in article.sections) {
        if (section.text.length == 0) {
            atLeastOneZeroLengthSection = YES;
            break;
        }
    }
    XCTAssert(atLeastOneZeroLengthSection);

    // Ensure "[MWKSection hasTextData]" returns YES if section html isn't nil - even if it's a zero length string.
    for (MWKSection *section in article.sections) {
        /*
           Reminder: zero length strings are *valid* section text data!
           Some sections have zero length strings - such as sections having immediate sub-sections.
           So [MWKSection hasTextData] *must* return YES if its "Section.html" file exists, even
           if it's empty, otherwise an article having any zero length sections would never appear to
           be cached.
         */
        XCTAssert([section hasTextData] == (section.text != nil));
    }
}

@end
