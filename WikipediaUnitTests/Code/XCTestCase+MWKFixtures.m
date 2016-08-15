#import "XCTestCase+MWKFixtures.h"
#import "XCTestCase+WMFBundleConvenience.h"
#import "MWKArticle.h"
#import "NSBundle+TestAssets.h"
#import "WMFRandomFileUtilities.h"

@implementation XCTestCase (MWKFixtures)

- (MWKArticle *)articleWithMobileViewJSONFixture:(NSString *)fixtureName
                                         withURL:(NSURL *)url
                                       dataStore:(MWKDataStore *)dataStore {
    return [[MWKArticle alloc] initWithURL:url
                                 dataStore:dataStore
                                      dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName][@"mobileview"]];
}

@end
