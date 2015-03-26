//
//  OldDataSchema.m
//  OldDataSchema
//
//  Created by Brion on 12/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "OldDataSchemaMigrator_Private.h"
#import "ArticleCoreDataObjects.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "ArticleDataContextSingleton.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "Article+ConvenienceAccessors.h"

@interface OldDataSchemaMigrator ()

@property (nonatomic, strong) ArticleDataContextSingleton* context;
@property (nonatomic, strong) NSMutableSet* savedTitles;

@end

@implementation OldDataSchemaMigrator

- (instancetype)init {
    self = [super init];
    if (self) {
        _savedTitles = [[NSMutableSet alloc] init];
        if (self.exists) {
            _context = [ArticleDataContextSingleton sharedInstance];
        } else {
            _context = nil;
        }
    }
    return self;
}

- (NSString*)sqlitePath {
    NSArray* documentPaths     = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentRootPath = [documentPaths objectAtIndex:0];
    NSString* filePath         = [documentRootPath stringByAppendingPathComponent:@"articleData6.sqlite"];
    return filePath;
}

- (BOOL)exists {
    NSString* filePath = [self sqlitePath];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (void)removeOldData {
    NSString* filePath   = [self sqlitePath];
    NSString* backupPath = [filePath stringByAppendingString:@".bak"];
    NSError* err         = nil;
    [[NSFileManager defaultManager] moveItemAtPath:filePath
                                            toPath:backupPath
                                             error:&err];
    if (err) {
        NSLog(@"Error backing up %@: %@", filePath, err);
    }
}

- (void)migrateData {
    // TODO
    // 1) Go through saved article list, saving entries and (articles and images)
    // 2) Go through page reading history, saving entries and (articles and images) when not already transferred

    NSManagedObjectContext* context = [self.context backgroundContext];

    [context performBlock:^{
        NSFetchRequest* req = [NSFetchRequest fetchRequestWithEntityName:@"Saved"];
        req.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"dateSaved" ascending:YES]];
        NSError* err;
        NSArray* savedEntries = [context executeFetchRequest:req error:&err];

        if (err) {
            NSLog(@"Error reading old Saved entries: %@", err);
        }

        NSFetchRequest* req2 = [NSFetchRequest fetchRequestWithEntityName:@"History"];
        req2.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"dateVisited" ascending:YES]];
        NSError* err2;
        NSArray* historyEntries = [context executeFetchRequest:req2 error:&err2];

        if (err2) {
            NSLog(@"Error reading old History entries: %@", err2);
        }

        NSUInteger totalArticlesToMigrate = [savedEntries count];
        __block NSUInteger numberOfArticlesMigrated = 0;

        void (^ incrementAndNotify)(void) = ^void (void) {
            numberOfArticlesMigrated++;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressDelegate oldDataSchema:self didUpdateProgressWithArticlesCompleted:numberOfArticlesMigrated total:totalArticlesToMigrate];
            });
        };

        for (History* history in historyEntries) {
            [self migrateHistory:history];
        }

        for (Saved* saved in savedEntries) {
            [self migrateSaved:saved];
            [self migrateArticle:saved.article];
            incrementAndNotify();
        }

        [self.context saveContextAndPropagateChangesToStore:context completionBlock:^(NSError* error) {
            [self removeOldData];

            if (error) {
                [self.progressDelegate oldDataSchema:self didFinishWithError:error];
            } else {
                [self.progressDelegate oldDataSchemaDidFinishMigration:self];
            }
        }];
    }];
}

- (MWKSite*)migrateArticleSite:(Article*)article {
    return [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:article.domain];
}

- (MWKTitle*)migrateArticleTitle:(Article*)article {
    return [[self migrateArticleSite:article] titleWithString:article.title];
}

- (void)migrateSaved:(Saved*)saved {
    NSDictionary* dict = [self exportSaved:saved];
    [self.delegate oldDataSchema:self migrateSavedEntry:dict];
}

- (void)migrateHistory:(History*)history {
    NSDictionary* dict = [self exportHistory:history];
    [self.delegate oldDataSchema:self migrateHistoryEntry:dict];
}

- (void)migrateArticle:(Article*)article {
    NSString* key = [NSString stringWithFormat:@"%@:%@", article.domain, article.title];
    if ([self.savedTitles containsObject:key]) {
        // already imported this article
    } else {
        // Record for later to avoid dupe imports
        [self.savedTitles addObject:key];

        MWKArticle* migratedArticle = [self.delegate oldDataSchema:self migrateArticle:[self exportArticle:article]];

        Image* thumbnail = article.thumbnailImage;
        if (thumbnail) {
            [self migrateThumbnailImage:thumbnail article:article newArticle:migratedArticle];
        }
        // HACK: setting thumbnailURL after migration prevents it from being added to the image list twice
        migratedArticle.thumbnailURL = thumbnail.sourceUrl;

        for (Section* section in [article sectionsBySectionId]) {
            for (SectionImage* sectionImage in [section sectionImagesByIndex]) {
                [self migrateImage:sectionImage newArticle:migratedArticle];
            }
        }

        // set the lead image to the first non-thumb image
        if ([migratedArticle.images count]) {
            // thumbnail should always be first, if it's present (see above assertion)
            NSUInteger leadImageURLIndex = (thumbnail && migratedArticle.images.count > 1) ? 1 : 0;
            migratedArticle.imageURL = [migratedArticle.images imageURLAtIndex:leadImageURLIndex];
        }

        @try {
            [migratedArticle save];
        } @catch (NSException* saveException) {
            NSLog(@"Failed to save article after importing images: %@", saveException);
            NSParameterAssert(!saveException);
        }
    }
}

- (void)migrateThumbnailImage:(Image*)thumbnailImage article:(Article*)article newArticle:(MWKArticle*)newArticle {
    NSDictionary* dict = [self exportThumbnailImage:thumbnailImage article:article];
    [self.delegate oldDataSchema:self migrateImage:dict newArticle:newArticle];
}

- (void)migrateImage:(SectionImage*)sectionImage newArticle:(MWKArticle*)newArticle {
    NSDictionary* dict = [self exportImage:sectionImage];
    [self.delegate oldDataSchema:self migrateImage:dict newArticle:newArticle];
}

- (NSDictionary*)exportSaved:(Saved*)saved {
    return @{
               @"domain": @"wikipedia.org",
               @"language": saved.article.domain,
               @"title": saved.article.title,
               @"date": [[NSDateFormatter wmf_iso8601Formatter] stringFromDate:saved.dateSaved]
    };
}

- (NSDictionary*)exportHistory:(History*)history {
    return @{
               @"domain": @"wikipedia.org",
               @"language": history.article.domain,
               @"title": history.article.title,
               @"date": [[NSDateFormatter wmf_iso8601Formatter] stringFromDate:history.dateVisited],
               @"discoveryMethod": history.discoveryMethod,
               @"scrollPosition": history.article.lastScrollY
    };
}

- (NSDictionary*)exportArticle:(Article*)article {
    NSParameterAssert(article);
    NSMutableDictionary* dict = [@{} mutableCopy];

    if (article.redirected) {
        dict[@"redirected"] = article.redirected;
    }
    if (article.lastmodified) {
        dict[@"lastmodified"] = [[NSDateFormatter wmf_iso8601Formatter] stringFromDate:article.lastmodified];
    }
    if (article.lastmodifiedby) {
        dict[@"lastmodifiedby"] = @{
            @"name": article.lastmodifiedby,
            @"gender": @"unknown"
        };
    }
    if (article.articleId) {
        dict[@"id"] = article.articleId;
    }
    if (article.languagecount) {
        dict[@"languagecount"] = article.languagecount;
    }
    if (article.displayTitle) {
        dict[@"displaytitle"] = article.displayTitle;
    }
    if (article.protectionStatus) {
        dict[@"protection"] = @{
            @"edit": @[article.protectionStatus]
        };
    }
    if (article.editable) {
        dict[@"editable"] = @"";
    }

    // sections!
    NSUInteger numSections = [article.section count];
    if (numSections) {
        dict[@"sections"] = [[NSMutableArray alloc] initWithCapacity:numSections];
        for (int i = 0; i < numSections; i++) {
            dict[@"sections"][i] = [NSNull null]; // stub out
        }
        for (Section* section in article.section) {
            int sectionId = [section.sectionId intValue];
            dict[@"sections"][sectionId] = [self exportSection:section];
        }
    }

    return @{
               @"language": article.domain,
               @"title": article.title,
               @"dict": dict
    };
}

- (NSDictionary*)exportSection:(Section*)section {
    NSParameterAssert(section);
    NSMutableDictionary* dict = [@{} mutableCopy];

    if (section.tocLevel) {
        dict[@"toclevel"] = section.tocLevel;
    }
    if (section.level) {
        dict[@"level"] = section.level;
    }
    if (section.title) {
        dict[@"line"] = section.title;
    }
    if (section.fromTitle) {
        dict[@"fromtitle"] = section.fromTitle;
    }
    if (section.anchor) {
        dict[@"anchor"] = section.anchor;
    }
    dict[@"id"] = section.sectionId;
    if (section.html) {
        dict[@"text"] = section.html;
    }

    return dict;
}

- (NSDictionary*)exportThumbnailImage:(Image*)image article:(Article*)article {
    NSParameterAssert(image);
    NSParameterAssert(article);
    ImageData* imageData = image.imageData;

    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    dict[@"domain"]   = @"wikipedia.org";
    dict[@"language"] = article.domain;
    dict[@"title"]    = article.title;

    dict[@"sectionId"] = @(-1);

    dict[@"sourceURL"] = image.sourceUrl;
    if (imageData.data) {
        dict[@"data"] = imageData.data;
    }

    return dict;
}

- (NSDictionary*)exportImage:(SectionImage*)sectionImage {
    NSParameterAssert(sectionImage);
    Section* section     = sectionImage.section;
    Article* article     = section.article;
    Image* image         = sectionImage.image;
    ImageData* imageData = image.imageData;

    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    dict[@"domain"]   = @"wikipedia.org";
    dict[@"language"] = article.domain;
    dict[@"title"]    = article.title;

    dict[@"sectionId"] = section.sectionId;

    dict[@"sourceURL"] = image.sourceUrl;
    if (imageData.data) {
        dict[@"data"] = imageData.data;
    }

    return dict;
}

@end
