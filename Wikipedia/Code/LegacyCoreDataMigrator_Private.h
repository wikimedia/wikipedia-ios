
#import "LegacyCoreDataMigrator.h"
#import "ArticleCoreDataObjects.h"
#import "MediaWikiKit.h"
@interface LegacyCoreDataMigrator ()

- (MWKSite*)migrateArticleSite:(Article*)article;
- (MWKTitle*)migrateArticleTitle:(Article*)article;
- (void)migrateArticle:(Article*)article;
- (void)migrateHistory:(History*)history;
- (void)migrateSaved:(Saved*)saved;
- (void)migrateImage:(SectionImage*)sectionImage newArticle:(MWKArticle*)newArticle;

@end
