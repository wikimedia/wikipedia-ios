#import "MWKTestCase.h"

@interface MWKArticleStoreTestCase : MWKTestCase

@property NSURL *siteURL;
@property NSURL *articleURL;
@property NSDictionary *json0;
@property NSDictionary *json1;
@property NSDictionary *jsonAnon;

@property NSString *basePath;
@property MWKDataStore *dataStore;
@property MWKArticle *article;

@end
