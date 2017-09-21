#import <XCTest/XCTest.h>
#import "SessionSingleton.h"
#import "WMFTestFixtureUtilities.h"
#import "MWKArticle+WMFSharing.h"
#import "MWKDataStore+TemporaryDataStore.h"

@interface MWKArticleExtractionTests : XCTestCase
@property (nonatomic) MWKArticle *article;
@end

@implementation MWKArticleExtractionTests

- (void)testMainPage {
    self.article =
        [[MWKArticle alloc] initWithURL:[[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Main Page"]
                              dataStore:nil];

    NSDictionary *mainPageMobileView = [[[self wmf_bundle]
        wmf_jsonFromContentsOfFile:@"MainPageMobileView"]
        objectForKey:@"mobileview"];

    [self.article importMobileViewJSON:mainPageMobileView];

    NSAssert([self.article isMain], @"supposed to be testing main pages!");

    XCTAssert([self.article.shareSnippet isEqualToString:@"Gary Cooper (1901–1961) was an American film actor known for his natural, authentic, and understated acting style. He was a movie star from the end of the silent film era through the end of the golden age of Classical Hollywood. Cooper began his career as a film extra and stunt rider and soon established himself as a Western hero in films such as The Virginian (1929). He played the lead in adventure films and dramas such as A Farewell to Arms (1932) and The Lives of a Bengal Lancer (1935), and extended his range of performances to include roles in most major film genres. He portrayed champions of the common man in films such as Mr. Deeds Goes to Town (1936), Meet John Doe (1941), Sergeant York (1941), The Pride of the Yankees (1942), and For Whom the Bell Tolls (1943). In his later years, he delivered award-winning performances in High Noon (1952) and Friendly Persuasion (1956). Cooper received three Academy Awards and appeared on the Motion Picture Herald exhibitors poll of top ten film personalities every year from 1936 to 1958. His screen persona embodied the American folk hero. (Full article...)Ongoing: Nepal earthquake – Yemeni Civil WarRecent deaths: Ruth Rendell – Maya Plisetskaya"]);

    XCTAssertFalse(self.article.hasMultipleLanguages);
}

- (void)testExpectedSnippetForObamaArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.shareSnippet isEqualToString:@"Barack Hussein Obama II (US i/bəˈrɑːk huːˈseɪn ɵˈbɑːmə/, born August 4, 1961) is the 44th and current President of the United States, and the first African American to hold the office. Born in Honolulu, Hawaii, Obama is a graduate of Columbia University and Harvard Law School, where he served as president of the Harvard Law Review. He was a community organizer in Chicago before earning his law degree. He worked as a civil rights attorney and taught constitutional law at the University of Chicago Law School from 1992 to 2004. He served three terms representing the 13th District in the Illinois Senate from 1997 to 2004, running unsuccessfully for the United States House of Representatives in 2000."]);

    XCTAssert(self.article.hasMultipleLanguages);
}

- (void)testExpectedSummaryForObamaArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"Barack Hussein Obama II is the 44th and current President of the United States, and the first African American to hold the office. Born in Honolulu, Hawaii, Obama is a graduate of Columbia University and Harvard Law School, where he served as president of the Harvard Law Review. He was a community organizer in Chicago before earning his law degree. He worked as a civil rights attorney and taught constitutional law at the University of Chicago Law School from 1992 to 2004. He served three ter"]);
}

- (void)testExpectedSummaryForGoatArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/Goat"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"The domestic goat is a subspecies of goat domesticated from the wild goat of southwest Asia and Eastern Europe. The goat is a member of the family Bovidae and is closely related to the sheep as both are in the goat-antelope subfamily Caprinae. There are over 300 distinct breeds of goat. Goats are one of the oldest domesticated species, and have been used for their milk, meat, hair, and skins over much of the world. In 2011, there were more than 924 million live goats around the globe, accordin"]);
}

- (void)testExpectedSummaryForHawaiiArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/Hawaii"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"Hawaii is the 50th and most recent U.S. state to join the United States, having joined on August 21, 1959. Hawaii is the only U.S. state located in Oceania and the only one composed entirely of islands. It is the northernmost island group in Polynesia, occupying most of an archipelago in the central Pacific Ocean. Hawaii is the only U.S. state not located in the Americas. The state does not observe daylight saving time. The state encompasses nearly the entire volcanic Hawaiian archipelago, which"]);
}

- (void)testExpectedSummaryForRinconHillSanFranciscoArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/Rincon Hill, San Francisco"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"Rincon Hill is a neighborhood in San Francisco, California. It is one of San Francisco's 49 hills, and one of its original \"Seven Hills.\" The relatively compact neighborhood is bounded by Folsom Street to the north, the Embarcadero to the east, Bryant Street on the south, and Essex Street to the west. Rincon Hill is located just south of the Transbay development area, part of the greater South of Market area. The hill is about 100 feet tall. Following the Califo"]);
}

- (void)testExpectedSummaryFor140NewMontgomeryArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/140 New Montgomery"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"140 New Montgomery Street, also known as the PacBell Building, in San Francisco's South of Market district is an Art Deco office tower located close to the St. Regis Museum Tower and the San Francisco Museum of Modern Art. The 26- floor building was originally called the Pacific Telephone Building when it was completed in 1925, and it was San Francisco's first significant skyscraper development when construction began in 1924. The building was the first high-rise south of Market Street, and the tall"]);
}

- (void)testExpectedSummaryForTunaArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/Tuna"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"A tuna is a saltwater finfish that belongs to the tribe Thunnini, a sub-grouping of the mackerel family – which together with the tunas, also includes the bonitos, mackerels, and Spanish mackerels. Thunnini comprises fifteen species across five genera, the sizes of which vary greatly, ranging from the bullet tuna up to the Atlantic bluefin tuna. The bluefin averages 2 m, and is believed to live for up to 50 years. Tuna and mackerel sharks are the only species of fish that can maintain a b"]);
}

- (void)testExpectedSummaryForTyrannosaurusArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/Tyrannosaurus"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"Tyrannosaurus is a genus of coelurosaurian theropod dinosaur. The species Tyrannosaurus rex, commonly abbreviated to T. rex, is one of the most well-represented of the large theropods. Tyrannosaurus lived throughout what is now western North America, on what was then an island continent known as Laramidia. Tyrannosaurus had a much wider range than other tyrannosaurids. Fossils are found in a variety of rock formations dating to the Maastrichtian age of the upper Cretaceous Period, 68 to"]);
}

- (void)testExpectedSummaryForWikimediaFoundationArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/Wikimedia Foundation"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"The Wikimedia Foundation is an American non-profit and charitable organization headquartered in San Francisco, California, that operates many wikis. The foundation is mostly known for hosting Wikipedia, the Internet encyclopedia, as well as Wiktionary, Wikiquote, Wikibooks, Wikisource, Wikimedia Commons, Wikispecies, Wikinews, Wikiversity, WikiData, Wikivoyage, Wikimedia Incubator, and Meta-Wiki. It also owned the now-defunct Nupedia. The organizatio"]);
}

- (void)testExpectedSummaryForMiniArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/Mini"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"The Mini is a small economy car made by the British Motor Corporation and its successors from 1959 until 2000. The original is considered a British icon of the 1960s. The Mini was the star car of the main character of animated TV series Mr. Bean. Its space-saving transverse engine front-wheel drive layout – allowing 80 percent of the area of the car's floorpan to be used for passengers and luggage – influenced a generation of car makers. In 1999 the Mini was voted the second most influential car of the"]);
}

- (void)testExpectedSummaryForTrigonometricFunctionsArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/Trigonometric functions"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"In mathematics, the trigonometric functions are functions of an angle. They relate the angles of a triangle to the lengths of its sides. Trigonometric functions are important in the study of triangles and modeling periodic phenomena, among many other applications. The most familiar trigonometric functions are the sine, cosine, and tangent. In the context of the standard unit circle, where a triangle is formed by a ray originating at the origin and making some angle with the x-axis, the sine of the"]);
}

- (void)testExpectedSummaryForCoveredBridgeLovechArticle {
    NSDictionary *obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"MobileView/en.m.wikipedia.org/Covered Bridge, Lovech"];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"foo"];
    self.article = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
    XCTAssert([self.article.summary isEqualToString:@"The Covered Bridge is, as the name suggests, a covered bridge in the town of Lovech, Bulgaria. The bridge crosses the Osam River, connecting the old and new town parts of Lovech, being possibly the most recognisable symbol of the town. After the bridge that then served the town was almost completely destroyed by a flood in 1872, the local police chief ordered the famous Bulgarian master builder Kolyu Ficheto to construct a new one. Ficheto personally chose the material for the wooden bridge. Each citizen"]);
}

@end
