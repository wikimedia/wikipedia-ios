#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@class MWKDataStore;

@interface XCTestCase (MWKFixtures)

/**
 * Create an article from fixture data, give it the specified title, and insert it into the given data store.
 *
 * The fixture data should be JSON, which can either be the raw response from mobileview or the JSON returned by
 * `-[MWKArticle dataExport]`. Keep in mind that other properties of the article might not be populated. 

 * @param fixtureName   The name of the JSON file you want to use (e.g. "Obama" for "Obama.json"), see description for
 *                      explanation of which fixtures are appropriate.
 * @param url The `NSURL` for the given fixture.
 * @param dataStore     Data store to insert the article into.
 *
 * @return An article object populated with data from the specified fixture.
 *
 */
- (MWKArticle *)articleWithMobileViewJSONFixture:(NSString *)fixtureName
                                         withURL:(NSURL *)url
                                       dataStore:(MWKDataStore *)dataStore;

@end

NS_ASSUME_NONNULL_END
