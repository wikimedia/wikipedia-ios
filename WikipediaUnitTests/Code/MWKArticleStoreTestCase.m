#import "MWKArticleStoreTestCase.h"
#import "MWKDataStore+TemporaryDataStore.h"

@implementation MWKArticleStoreTestCase

- (void)setUp {
    [super setUp];
    self.siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
    self.articleURL = [self.siteURL wmf_URLWithTitle:@"San Francisco"];
    self.json0 = [self loadJSON:@"section0"];
    self.json1 = [self loadJSON:@"section1-end"];
    self.jsonAnon = [self loadJSON:@"organization-anon"];

    self.dataStore = [MWKDataStore temporaryDataStore];
    self.article = [self.dataStore articleWithURL:self.articleURL];
}

- (void)tearDown {
    [self.dataStore removeFolderAtBasePath];
    [super tearDown];
}

@end
