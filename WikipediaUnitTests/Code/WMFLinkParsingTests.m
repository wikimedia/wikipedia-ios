#import <XCTest/XCTest.h>
#import "NSURL+WMFLinkParsing.h"
#import "NSURLComponents+WMFLinkParsing.h"


@interface WMFLinkParsingTests : XCTestCase

@end

@implementation WMFLinkParsingTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testWMFDomain {
    NSURL* URL = [NSURL URLWithString:@"https://en.wikipedia.org/wiki/Tyrannosaurus"];
    XCTAssertEqualObjects(@"wikipedia.org", URL.wmf_domain);
    XCTAssertEqualObjects(@"en", URL.wmf_language);
    XCTAssertEqualObjects(@"Tyrannosaurus", URL.wmf_title);
}

- (void)testWMFMobileDomain {
    NSURL* URL = [NSURL URLWithString:@"https://en.m.wikipedia.org/wiki/Tyrannosaurus"];
    XCTAssertEqualObjects(@"wikipedia.org", URL.wmf_domain);
    XCTAssertEqualObjects(@"en", URL.wmf_language);
    XCTAssertEqualObjects(@"Tyrannosaurus", URL.wmf_title);
}

- (void)testWMFDomainComponents {
    NSURLComponents* components = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"en" isMobile:NO];
    XCTAssertEqualObjects(@"en.wikipedia.org", components.host);
    components = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"en"];
    XCTAssertEqualObjects(@"en.wikipedia.org", components.host);
}

- (void)testWMFMobileDomainComponents {
    NSURLComponents* components = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"en" isMobile:YES];
    XCTAssertEqualObjects(@"en.m.wikipedia.org", components.host);
}

- (void)testWMFLinksFromLinks {
    NSURL* siteURL   = [NSURL wmf_URLWithDomain:@"wikipedia.org" language:@"fr"];
    NSURL* titledURL = [siteURL wmf_URLWithTitle:@"Main Page" fragment:nil];
    XCTAssertEqualObjects(@"https://fr.wikipedia.org/wiki/Main_Page", titledURL.absoluteString);
    titledURL = [siteURL wmf_URLWithTitle:@"Main Page"];
    XCTAssertEqualObjects(@"https://fr.wikipedia.org/wiki/Main_Page", titledURL.absoluteString);
    NSURL* titledAndFragmentedURL = [siteURL wmf_URLWithTitle:@"Main Page" fragment:@"section"];
    XCTAssertEqualObjects(@"https://fr.wikipedia.org/wiki/Main_Page#section", titledAndFragmentedURL.absoluteString);
    NSURL* mobileURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:YES];
    XCTAssertEqualObjects(@"https://fr.m.wikipedia.org/w/api.php", mobileURL.absoluteString);
}

- (void)testWMFInternalLinks {
    NSURL* siteURL = [NSURL wmf_URLWithDomain:@"wikipedia.org" language:@"en"];
    XCTAssertEqualObjects(@"en.wikipedia.org", siteURL.host);
    NSURL* pageURL = [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedInternalLink:@"/wiki/Main_Page"];
    XCTAssertEqualObjects(@"https://en.wikipedia.org/wiki/Main_Page", pageURL.absoluteString);
    NSURL* nonInternalPageURL = [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleAndFragment:@"/Main_Page"];
    XCTAssertEqualObjects(@"https://en.wikipedia.org/wiki/Main_Page", nonInternalPageURL.absoluteString);
}

- (void)testWMFLanguagelessLinks {
    NSURL* siteURL    = [NSURL wmf_URLWithDomain:@"mediawiki.org" language:nil];
    NSURL* desktopURL = siteURL.wmf_desktopURL;
    XCTAssertEqualObjects(@"https://mediawiki.org", desktopURL.absoluteString);
    NSURL* mobileURL = siteURL.wmf_mobileURL;
    XCTAssertEqualObjects(@"https://m.mediawiki.org", mobileURL.absoluteString);
    NSURL* apiURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:NO];
    XCTAssertEqualObjects(@"https://mediawiki.org/w/api.php", apiURL.absoluteString);
    NSURL* mobileAPIURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:YES];
    XCTAssertEqualObjects(@"https://m.mediawiki.org/w/api.php", mobileAPIURL.absoluteString);
}

- (void)testWMFLanguagelessMobileLinks {
    NSURL* siteURL    = [NSURL URLWithString:@"https://m.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ"];
    NSURL* desktopURL = siteURL.wmf_desktopURL;
    XCTAssertEqualObjects(@"https://mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ", desktopURL.absoluteString);
    NSURL* mobileURL = siteURL.wmf_mobileURL;
    XCTAssertEqualObjects(@"https://m.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ", mobileURL.absoluteString);
    NSURL* apiURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:NO];
    XCTAssertEqualObjects(@"https://mediawiki.org/w/api.php", apiURL.absoluteString);
    NSURL* mobileAPIURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:YES];
    XCTAssertEqualObjects(@"https://m.mediawiki.org/w/api.php", mobileAPIURL.absoluteString);
}

- (void)testWMFSpecialCharacters {
    NSURL* URL        = [NSURL URLWithString:@"https://en.m.wikipedia.org"];
    NSURL* kirkjubURL = [URL wmf_URLWithTitle:@"Kirkjubæjarklaustur"];
    XCTAssertEqualObjects(@"https://en.m.wikipedia.org/wiki/Kirkjub%C3%A6jarklaustur", kirkjubURL.absoluteString);
    NSURL* eldgjaURL = [URL wmf_URLWithTitle:@"Eldgjá"];
    XCTAssertEqualObjects(@"https://en.m.wikipedia.org/wiki/Eldgj%C3%A1", eldgjaURL.absoluteString);
}

@end
