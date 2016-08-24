#import <XCTest/XCTest.h>
#import <CoreSpotlight/CoreSpotlight.h>

@interface NSURL (SpotlightExtensions)
- (CSSearchableItemAttributeSet *_Nullable)searchableItemAttributes;
@end

@interface MWKArticle (SpotlightExtensions)
- (CSSearchableItemAttributeSet *)searchableItemAttributes;
@end

@interface NSURL_searchableItemAttributes_Test : XCTestCase
@end

@implementation NSURL_searchableItemAttributes_Test

- (void)testSearchableItemAttributeSetURL {

    NSURL *url = [NSURL URLWithString:@"https://en.wikipedia.org/wiki/This_Is_A_Test"];
    CSSearchableItemAttributeSet *attributes = url.searchableItemAttributes;

    XCTAssertEqualObjects(attributes.contentType, @"com.apple.internet-location");
    XCTAssertEqualObjects(attributes.title, @"This Is A Test");
    XCTAssertEqualObjects(attributes.displayName, @"This Is A Test");

    NSArray *keywords = @[@"Wikipedia", @"Wikimedia", @"Wiki", @"This", @"Is", @"A", @"Test"];

    XCTAssertEqualObjects(attributes.keywords, keywords);
    XCTAssertEqualObjects(attributes.identifier, @"https://en.wikipedia.org/wiki/This_Is_A_Test");
    XCTAssertEqualObjects(attributes.relatedUniqueIdentifier, @"https://en.wikipedia.org/wiki/This_Is_A_Test");
}

- (void)testSearchableItemAttributeSetURLReturnsNilForNonWikiResources {
    NSURL *url = [NSURL URLWithString:@"https://en.foo.org/"];
    XCTAssertNil(url.searchableItemAttributes);
}
@end

@interface MWKArticle_searchableItemAttributes_Test : XCTestCase
@end

@implementation MWKArticle_searchableItemAttributes_Test
- (void)testSearchableItemAttributeSetURL {

    NSURL *url = [NSURL URLWithString:@"https://en.wikipedia.org/wiki/This_Is_A_Test"];
    MWKArticle *article = [[MWKArticle alloc] initWithURL:url];
    [article setValue:@"entityDescription" forKey:@"entityDescription"];
    [article setValue:@"summary" forKey:@"summary"];
    article.imageURL = @"https://en.wikipedia.org/wiki/This_Is_A_Test";

    CSSearchableItemAttributeSet *attributes = article.searchableItemAttributes;

    XCTAssertEqualObjects(attributes.contentType, @"com.apple.internet-location");
    XCTAssertEqualObjects(attributes.title, @"This Is A Test");
    XCTAssertEqualObjects(attributes.subject, @"entityDescription");
    XCTAssertEqualObjects(attributes.contentDescription, @"summary");
}

@end
