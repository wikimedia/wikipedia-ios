#import <XCTest/XCTest.h>
@import WMF;

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
    NSURL *URL = [NSURL URLWithString:@"https://en.wikipedia.org/wiki/Tyrannosaurus"];
    XCTAssertEqualObjects(@"wikipedia.org", URL.wmf_domain);
    XCTAssertEqualObjects(@"en", URL.wmf_language);
    XCTAssertEqualObjects(@"Tyrannosaurus", URL.wmf_title);
}

- (void)testWMFMobileDomain {
    NSURL *URL = [NSURL URLWithString:@"https://en.m.wikipedia.org/wiki/Tyrannosaurus"];
    XCTAssertEqualObjects(@"wikipedia.org", URL.wmf_domain);
    XCTAssertEqualObjects(@"en", URL.wmf_language);
    XCTAssertEqualObjects(@"Tyrannosaurus", URL.wmf_title);
}

- (void)testWMFDomainComponents {
    NSURLComponents *components = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"en" isMobile:NO];
    XCTAssertEqualObjects(@"en.wikipedia.org", components.host);
    components = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"en"];
    XCTAssertEqualObjects(@"en.wikipedia.org", components.host);
}

- (void)testWMFMobileDomainComponents {
    NSURLComponents *components = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"en" isMobile:YES];
    XCTAssertEqualObjects(@"en.m.wikipedia.org", components.host);
}

- (void)testWMFLinksFromLinks {
    NSURL *siteURL = [NSURL wmf_URLWithDomain:@"wikipedia.org" language:@"fr"];
    NSURL *titledURL = [siteURL wmf_URLWithTitle:@"Main Page" fragment:nil query:nil];
    XCTAssertEqualObjects(@"https://fr.wikipedia.org/wiki/Main_Page", titledURL.absoluteString);
    titledURL = [siteURL wmf_URLWithTitle:@"Main Page"];
    XCTAssertEqualObjects(@"https://fr.wikipedia.org/wiki/Main_Page", titledURL.absoluteString);
    NSURL *titledAndFragmentedURL = [siteURL wmf_URLWithTitle:@"Main Page" fragment:@"section" query:nil];
    XCTAssertEqualObjects(@"https://fr.wikipedia.org/wiki/Main_Page#section", titledAndFragmentedURL.absoluteString);
    NSURL *mobileURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:YES];
    XCTAssertEqualObjects(@"https://fr.m.wikipedia.org/w/api.php", mobileURL.absoluteString);
}

- (void)testWMFInternalLinks {
    NSURL *siteURL = [NSURL wmf_URLWithDomain:@"wikipedia.org" language:@"en"];
    XCTAssertEqualObjects(@"en.wikipedia.org", siteURL.host);
    NSURL *pageURL = [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedInternalLink:@"/wiki/Main_Page"];
    XCTAssertEqualObjects(@"https://en.wikipedia.org/wiki/Main_Page", pageURL.absoluteString);
    NSURL *nonInternalPageURL = [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleQueryAndFragment:@"Main_Page"];
    XCTAssertEqualObjects(@"https://en.wikipedia.org/wiki/Main_Page", nonInternalPageURL.absoluteString);
}

- (void)testQueryPreservation {
    NSURL *siteURL = [NSURL wmf_URLWithDomain:@"wikipedia.org" language:@"en"];
    NSURL *nonInternalPageURL = [NSURL wmf_URLWithSiteURL:siteURL escapedDenormalizedTitleQueryAndFragment:@"Main_Page?wprov=stii1&a=%3F#blah"];
    XCTAssertEqualObjects(@"https://en.wikipedia.org/wiki/Main_Page?wprov=stii1&a=%3F#blah", nonInternalPageURL.absoluteString);
}

- (void)testWMFLanguagelessLinks {
    NSURL *siteURL = [NSURL wmf_URLWithDomain:@"mediawiki.org" language:nil];
    NSURL *desktopURL = [NSURL wmf_desktopURLForURL:siteURL];
    XCTAssertEqualObjects(@"https://mediawiki.org", desktopURL.absoluteString);
    NSURL *mobileURL = [NSURL wmf_mobileURLForURL:siteURL];
    XCTAssertEqualObjects(@"https://m.mediawiki.org", mobileURL.absoluteString);
    NSURL *apiURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:NO];
    XCTAssertEqualObjects(@"https://mediawiki.org/w/api.php", apiURL.absoluteString);
    NSURL *mobileAPIURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:YES];
    XCTAssertEqualObjects(@"https://m.mediawiki.org/w/api.php", mobileAPIURL.absoluteString);
}

- (void)testWMFLanguagelessMobileLinks {
    NSURL *siteURL = [NSURL URLWithString:@"https://m.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ"];
    NSURL *desktopURL = [NSURL wmf_desktopURLForURL:siteURL];
    XCTAssertEqualObjects(@"https://mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ", desktopURL.absoluteString);
    NSURL *mobileURL = [NSURL wmf_mobileURLForURL:siteURL];
    XCTAssertEqualObjects(@"https://m.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ", mobileURL.absoluteString);
    NSURL *apiURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:NO];
    XCTAssertEqualObjects(@"https://mediawiki.org/w/api.php", apiURL.absoluteString);
    NSURL *mobileAPIURL = [siteURL wmf_URLWithPath:@"/w/api.php" isMobile:YES];
    XCTAssertEqualObjects(@"https://m.mediawiki.org/w/api.php", mobileAPIURL.absoluteString);
}

- (void)testWMFSpecialCharacters {
    NSURL *URL = [NSURL URLWithString:@"https://en.m.wikipedia.org"];
    NSURL *kirkjubURL = [URL wmf_URLWithTitle:@"Kirkjubæjarklaustur"];
    XCTAssertEqualObjects(@"https://en.m.wikipedia.org/wiki/Kirkjub%C3%A6jarklaustur", kirkjubURL.absoluteString);
    NSURL *eldgjaURL = [URL wmf_URLWithTitle:@"Eldgjá"];
    XCTAssertEqualObjects(@"https://en.m.wikipedia.org/wiki/Eldgj%C3%A1", eldgjaURL.absoluteString);
}

- (void)testTitlesWithSlashes {
    NSURL *URL = [NSURL URLWithString:@"https://en.m.wikipedia.org"];
    NSURL *devNullURL = [URL wmf_URLWithTitle:@"/dev/null"];
    XCTAssertEqualObjects(@"https://en.m.wikipedia.org/wiki/%2Fdev%2Fnull", devNullURL.absoluteString);
    NSURL *albumURL = [URL wmf_URLWithTitle:@"/2016ALBUM/"];
    XCTAssertEqualObjects(@"https://en.m.wikipedia.org/wiki/%2F2016ALBUM%2F", albumURL.absoluteString);
}

- (void)testWMFCanonicalMappingURLComponents {
    NSURL *one = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"it" title:@"Teoria della relatività"].URL;
    NSURL *two = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"it" title:@"Teoria della relativit\u00E0"].URL;
    NSURL *three = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"it" title:@"Teoria della relativita\u0300"].URL;
    XCTAssertEqualObjects(one, two);
    XCTAssertEqualObjects(two, three);

    one = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"it" title:@"Teoria della relatività" fragment:@"La_relatività_galileiana"].URL;
    two = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"it" title:@"Teoria della relativit\u00E0" fragment:@"La_relativit\u00E0_galileiana"].URL;
    three = [NSURLComponents wmf_componentsWithDomain:@"wikipedia.org" language:@"it" title:@"Teoria della relativita\u0300" fragment:@"La_relativita\u0300_galileiana"].URL;
    XCTAssertEqualObjects(one, two);
    XCTAssertEqualObjects(two, three);
}

- (void)testWMFNormalizedTitleCanonicalMapping {
    NSString *one = [@"Teoria della relatività" wmf_denormalizedPageTitle];
    NSString *two = [@"Teoria della relativit\u00E0" wmf_denormalizedPageTitle];
    NSString *three = [@"Teoria della relativita\u0300" wmf_denormalizedPageTitle];
    XCTAssertEqualObjects(one, two);
    XCTAssertEqualObjects(two, three);
    XCTAssertEqualObjects(three, @"Teoria_della_relativit\u00E0");

    one = [@"Teoria_della_relatività" wmf_normalizedPageTitle];
    two = [@"Teoria_della_relativit\u00E0" wmf_normalizedPageTitle];
    three = [@"Teoria_della_relativita\u0300" wmf_normalizedPageTitle];
    XCTAssertEqualObjects(one, two);
    XCTAssertEqualObjects(two, three);
    XCTAssertEqualObjects(three, @"Teoria della relativit\u00E0");

    one = [@"Teoria_della_relativit\u00E0" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];  //Teoria_della_relativit%C3%A0
    two = [@"Teoria_della_relativita\u0300" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]; //Teoria_della_relativita%CC%80
    one = [one wmf_unescapedNormalizedPageTitle];
    two = [two wmf_unescapedNormalizedPageTitle];
    XCTAssertEqualObjects(one, two);
    XCTAssertEqualObjects(two, @"Teoria della relativit\u00E0");
}

- (void)testWMFCanonicalMapping {
    NSURL *URL = [NSURL URLWithString:@"https://es.wikipedia.org"];
    NSURL *ole = [URL wmf_URLWithTitle:@"Olé"];
    NSURL *secondOle = [URL wmf_URLWithTitle:@"Ol\u00E9"];
    NSURL *thirdOle = [URL wmf_URLWithTitle:@"Ole\u0301"];
    XCTAssertEqualObjects(ole, secondOle);
    XCTAssertEqualObjects(ole, thirdOle);

    ole = [URL wmf_URLWithTitle:@"Olé" fragment:@"Olé" query:nil];
    secondOle = [URL wmf_URLWithTitle:@"Ol\u00E9" fragment:@"Ol\u00E9" query:nil];
    thirdOle = [URL wmf_URLWithTitle:@"Ole\u0301" fragment:@"Ole\u0301" query:nil];
    XCTAssertEqualObjects(ole, secondOle);
    XCTAssertEqualObjects(ole, thirdOle);

    ole = [URL wmf_URLWithPath:@"/wiki/Olé#Olé" isMobile:NO];
    secondOle = [URL wmf_URLWithPath:@"/wiki/Ol\u00E9#Ol\u00E9" isMobile:NO];
    thirdOle = [URL wmf_URLWithPath:@"/wiki/Ole\u0301#Ole\u0301" isMobile:NO];
    XCTAssertEqualObjects(ole, secondOle);
    XCTAssertEqualObjects(ole, thirdOle);
}

- (void)testEventLoggingLabel {
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://en.wikipedia.org/wiki/ISO_8601?event_logging_label=read_more"];
    NSString *readMore = components.wmf_eventLoggingLabel;
    XCTAssertEqualObjects(readMore, @"read_more");
    XCTAssertEqualObjects(components.wmf_componentsByRemovingInternalQueryParameters.URL.absoluteString, @"https://en.wikipedia.org/wiki/ISO_8601");
}

- (void)testEventLoggingLabelWithMultipleParams {
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://en.wikipedia.org/wiki/ISO_8601?event_logging_label=read_more&wprov=stii1"];
    NSString *readMore = components.wmf_eventLoggingLabel;
    XCTAssertEqualObjects(readMore, @"read_more");
    XCTAssertEqualObjects(components.wmf_componentsByRemovingInternalQueryParameters.URL.absoluteString, @"https://en.wikipedia.org/wiki/ISO_8601?wprov=stii1");
}

- (void)testContentLanguageCodeProperty {
    NSString *languageCode = @"zh";
    NSString *languageVariantCode = @"zh-hans";
    
    // If languageVariantCode is non-nil and non-empty string, wmf_contentLanguageCode returns languageVariantCode
    NSURL *url = [NSURL wmf_URLWithDefaultSiteAndlanguage:languageCode];
    url.wmf_languageVariantCode = languageVariantCode;
    XCTAssertEqualObjects(url.wmf_contentLanguageCode, languageVariantCode);
    
    // If languageVariantCode is nil, contentLanguageCode returns languageCode
    url = [NSURL wmf_URLWithDefaultSiteAndlanguage:languageCode];
    XCTAssertEqualObjects(url.wmf_contentLanguageCode, languageCode);
    
    // If languageVariantCode is an empty string, contentLanguageCode returns languageCode
    url = [NSURL wmf_URLWithDefaultSiteAndlanguage:languageCode];
    url.wmf_languageVariantCode = @"";
    XCTAssertEqualObjects(url.wmf_contentLanguageCode, languageCode);
}


@end
