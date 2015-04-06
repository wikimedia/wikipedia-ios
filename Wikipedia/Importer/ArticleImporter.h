//  Created by Monte Hurd on 4/25/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@interface ArticleImporter : NSObject

// Parameter "articleDictionaries" is an array of NSDictionaries.
// Each dictionary must have "domain" and "title" keys (NSString values)

// Example:
/*

    NSArray *articles = @[
        @{@"domain": @"en", @"title": @"food"},
        @{@"domain": @"fr", @"title": @"nourriture"},
        @{@"domain": @"en", @"title": @"bird"}
    ];

    ArticleImporter *importer = [[ArticleImporter alloc] init];

    [importer importArticles:articles];

 */

- (void)importArticles:(NSArray*)articleDictionaries;

@end
