
#import "MediaWikiKit.h"

#import <BlocksKit/BlocksKit.h>
#import "NSString+WMFExtras.h"
#import "Wikipedia-Swift.h"

#import <BlocksKit/BlocksKit.h>

NSString* const MWKArticleSavedNotification      = @"MWKArticleSavedNotification";
NSString* const MWKArticleKey                    = @"MWKArticleKey";
NSString* const MWKDataStoreValidImageSitePrefix = @"//upload.wikimedia.org/";

NSString* MWKCreateImageURLWithPath(NSString* path) {
    return [MWKDataStoreValidImageSitePrefix stringByAppendingString:path];
}

static NSString* const MWKImageInfoFilename = @"ImageInfo.plist";

@interface MWKDataStore ()

@property (readwrite, strong, nonatomic) MWKUserDataStore* userDataStore;
@property (readwrite, copy, nonatomic) NSString* basePath;
@property (readwrite, strong, nonatomic) NSCache* articleCache;

@property (readwrite, nonatomic, strong) dispatch_queue_t cacheRemovalQueue;
@property (readwrite, nonatomic, getter = isCacheRemovalActive) BOOL cacheRemovalActive;

@end

@implementation MWKDataStore


#pragma mark - Setup / Teardown

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    return [self initWithBasePath:[[self class] mainDataStorePath]];
}

- (instancetype)initWithBasePath:(NSString*)basePath {
    self = [super init];
    if (self) {
        self.basePath = basePath;
        NSString* pathToExclude         = [self pathForSites];
        NSError* directoryCreationError = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:pathToExclude withIntermediateDirectories:YES attributes:nil error:&directoryCreationError]) {
            DDLogError(@"Error creating MWKDataStore path: %@", directoryCreationError);
        }
        NSURL* directoryURL         = [NSURL fileURLWithPath:pathToExclude isDirectory:YES];
        NSError* excludeBackupError = nil;
        if (![directoryURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&excludeBackupError]) {
            DDLogError(@"Error excluding MWKDataStore path from backup: %@", excludeBackupError);
        }
        self.articleCache            = [[NSCache alloc] init];
        self.articleCache.countLimit = 50;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRecievememoryWarningWithNotifcation:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        self.userDataStore     = [[MWKUserDataStore alloc] initWithDataStore:self];
        self.cacheRemovalQueue = dispatch_queue_create("org.wikimedia.cache_removal", DISPATCH_QUEUE_SERIAL);
        dispatch_async(self.cacheRemovalQueue, ^{ self.cacheRemovalActive = true; });
    }
    return self;
}

#pragma mark - Class methods

+ (NSString*)mainDataStorePath {
    NSString* documentsFolder =
        [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [documentsFolder stringByAppendingPathComponent:@"Data"];
}

#pragma mark - Memory

- (void)didRecievememoryWarningWithNotifcation:(NSNotification*)note {
    [self.articleCache removeAllObjects];
}

#pragma mark - path methods

- (NSString*)joinWithBasePath:(NSString*)path {
    return [self.basePath stringByAppendingPathComponent:path];
}

- (NSString*)pathForSites {
    return [self joinWithBasePath:@"sites"];
}

- (NSString*)pathForDomainInURL:(NSURL*)url {
    NSString* sitesPath  = [self pathForSites];
    NSString* domainPath = [sitesPath stringByAppendingPathComponent:url.wmf_domain];
    return [domainPath stringByAppendingPathComponent:url.wmf_language];
}

- (NSString*)pathForArticlesInDomainFromURL:(NSURL*)url {
    NSString* sitePath = [self pathForDomainInURL:url];
    return [sitePath stringByAppendingPathComponent:@"articles"];
}

/// Returns the folder where data for the correspnoding title is stored.
- (NSString*)pathForArticleURL:(NSURL*)url {
    NSString* articlesPath = [self pathForArticlesInDomainFromURL:url];
    NSString* encTitle     = [self safeFilenameWithString:url.wmf_titleWithUnderScores];
    return [articlesPath stringByAppendingPathComponent:encTitle];
}

- (NSString*)pathForArticle:(MWKArticle*)article {
    return [self pathForArticleURL:article.url];
}

- (NSString*)pathForSectionsInArticleWithURL:(NSURL*)url {
    NSString* articlePath = [self pathForArticleURL:url];
    return [articlePath stringByAppendingPathComponent:@"sections"];
}

- (NSString*)pathForSectionId:(NSUInteger)sectionId inArticleWithURL:(NSURL*)url {
    NSString* sectionsPath = [self pathForSectionsInArticleWithURL:url];
    NSString* sectionName  = [NSString stringWithFormat:@"%d", (int)sectionId];
    return [sectionsPath stringByAppendingPathComponent:sectionName];
}

- (NSString*)pathForSection:(MWKSection*)section {
    return [self pathForSectionId:section.sectionId inArticleWithURL:section.url];
}

- (NSString*)pathForImagesWithArticleURL:(NSURL*)url {
    NSString* articlePath = [self pathForArticleURL:url];
    return [articlePath stringByAppendingPathComponent:@"Images"];
}

- (NSString*)pathForImageURL:(NSString*)imageURL forArticleURL:(NSURL*)articleURL{
    NSString* imagesPath = [self pathForImagesWithArticleURL:articleURL];
    NSString* encURL     = [self safeFilenameWithImageURL:imageURL];
    return encURL ? [imagesPath stringByAppendingPathComponent:encURL] : nil;
}

- (NSString*)pathForImage:(MWKImage*)image {
    return [self pathForImageURL:image.sourceURLString forArticleURL:image.article.url];
}

- (NSString*)pathForImageInfoForArticleWithURL:(NSURL*)url {
    return [[self pathForArticleURL:url] stringByAppendingPathComponent:MWKImageInfoFilename];
}

- (NSString*)safeFilenameWithString:(NSString*)str {
    // Escape only % and / with percent style for readability
    NSString* encodedStr = [str stringByReplacingOccurrencesOfString:@"%" withString:@"%25"];
    encodedStr = [encodedStr stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];

    return encodedStr;
}

- (NSString*)stringWithSafeFilename:(NSString*)str {
    return [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)safeFilenameWithImageURL:(NSString*)str {
    str = [str wmf_schemelessURL];

    if (![str hasPrefix:MWKDataStoreValidImageSitePrefix]) {
        return nil;
    }

    NSString* suffix   = [str substringFromIndex:[MWKDataStoreValidImageSitePrefix length]];
    NSString* fileName = [suffix lastPathComponent];

    // Image URLs are already percent-encoded, so don't double-encode em.
    // In fact, we want to decode them...
    // If we don't, long Unicode filenames may not fit in the filesystem.
    NSString* decodedFileName = [fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    return decodedFileName;
}

#pragma mark - save methods

- (BOOL)ensurePathExists:(NSString*)path error:(NSError**)error {
    return [[NSFileManager defaultManager] createDirectoryAtPath:path
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:error];
}

- (void)ensurePathExists:(NSString*)path {
    [self ensurePathExists:path error:NULL];
}

- (BOOL)saveData:(NSData*)data toFile:(NSString*)filename atPath:(NSString*)path error:(NSError**)error {
    NSAssert([filename length] > 0, @"No file path given for saving data");
    if (!filename) {
        return NO;
    }
    [self ensurePathExists:path error:error];
    NSString* absolutePath = [path stringByAppendingPathComponent:filename];
    return [data writeToFile:absolutePath options:NSDataWritingAtomic error:error];
}

- (void)saveData:(NSData*)data path:(NSString*)path name:(NSString*)name {
    NSError* error = nil;
    [self saveData:data toFile:name atPath:path error:&error];
    NSAssert(error == nil, @"Error saving image to data store: %@", error);
}

- (BOOL)saveArray:(NSArray*)array path:(NSString*)path name:(NSString*)name error:(NSError**)error {
    NSData* data = [NSPropertyListSerialization dataWithPropertyList:array format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    return [self saveData:data toFile:name atPath:path error:error];
}

- (void)saveArray:(NSArray*)array path:(NSString*)path name:(NSString*)name {
    [self saveArray:array path:path name:name error:NULL];
}

- (BOOL)saveDictionary:(NSDictionary*)dict path:(NSString*)path name:(NSString*)name error:(NSError**)error {
    NSData* data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    return [self saveData:data toFile:name atPath:path error:error];
}

- (void)saveDictionary:(NSDictionary*)dict path:(NSString*)path name:(NSString*)name {
    [self saveDictionary:dict path:path name:name error:NULL];
}

- (BOOL)saveString:(NSString*)string path:(NSString*)path name:(NSString*)name error:(NSError**)error {
    return [self saveData:[string dataUsingEncoding:NSUTF8StringEncoding] toFile:name atPath:path error:error];
}

- (void)saveString:(NSString*)string path:(NSString*)path name:(NSString*)name {
    [self saveString:string path:path name:name error:NULL];
}

- (void)saveArticle:(MWKArticle*)article {
    if (article.url.wmf_title == nil) {
        return;
    }
    if ([article isMain]) {
        return;
    }
    if (article.url.wmf_isNonStandardURL) {
        return;
    }

    NSString* path       = [self pathForArticle:article];
    NSDictionary* export = [article dataExport];
    [self saveDictionary:export path:path name:@"Article.plist"];
    [self.articleCache setObject:article forKey:article.url];
    dispatchOnMainQueue(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MWKArticleSavedNotification object:self userInfo:@{MWKArticleKey: article}];
    });
}

- (void)saveSection:(MWKSection*)section {
    if ([section.article isMain]) {
        return;
    }
    NSString* path       = [self pathForSection:section];
    NSDictionary* export = [section dataExport];
    [self saveDictionary:export path:path name:@"Section.plist"];
}

- (void)saveSectionText:(NSString*)html section:(MWKSection*)section {
    if ([section.article isMain]) {
        return;
    }
    NSString* path = [self pathForSection:section];
    [self saveString:html path:path name:@"Section.html"];
}

- (void)saveImage:(MWKImage*)image {
    if ([image.article isMain]) {
        return;
    }
    NSString* path       = [self pathForImage:image];
    NSDictionary* export = [image dataExport];
    [self saveDictionary:export path:path name:@"Image.plist"];
}

- (BOOL)saveHistoryList:(MWKHistoryList*)list error:(NSError**)error {
    NSString* path       = self.basePath;
    NSDictionary* export = @{@"entries": [list dataExport]};
    return [self saveDictionary:export path:path name:@"History.plist" error:error];
}

- (BOOL)saveSavedPageList:(MWKSavedPageList*)list error:(NSError**)error {
    return [self saveDictionary:[list dataExport]
                           path:self.basePath
                           name:@"SavedPages.plist"
                          error:error];
}

- (BOOL)saveRecentSearchList:(MWKRecentSearchList*)list error:(NSError**)error {
    NSString* path       = self.basePath;
    NSDictionary* export = @{@"entries": [list dataExport]};
    return [self saveDictionary:export path:path name:@"RecentSearches.plist" error:error];
}

- (void)saveImageInfo:(NSArray*)imageInfo forArticleURL:(NSURL*)url {
    [self saveArray:[imageInfo bk_map:^id (MWKImageInfo* obj) { return [obj dataExport]; }]
               path:[self pathForArticleURL:url]
               name:MWKImageInfoFilename];
}

#pragma mark - load methods

- (MWKArticle*)memoryCachedArticleWithURL:(NSURL*)url{
    return [self.articleCache objectForKey:url];
}

- (MWKArticle*)existingArticleWithURL:(NSURL*)url {
    MWKArticle* existingArticle =
        [self memoryCachedArticleWithURL:url] ? : [self articleFromDiskWithURL:url];
    if (existingArticle) {
        [self.articleCache setObject:existingArticle forKey:url];
    }
    return existingArticle;
}

- (MWKArticle*)articleFromDiskWithURL:(NSURL*)url {
    NSString* path     = [self pathForArticleURL:url];
    NSString* filePath = [path stringByAppendingPathComponent:@"Article.plist"];
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (!dict) {
        return nil;
    }
    return [[MWKArticle alloc] initWithURL:url dataStore:self dict:dict];
}

- (MWKArticle*)articleWithURL:(NSURL*)url {
    return [self existingArticleWithURL:url] ? : [[MWKArticle alloc] initWithURL:url dataStore:self];
}

- (MWKSection*)sectionWithId:(NSUInteger)sectionId article:(MWKArticle*)article {
    NSString* path     = [self pathForSectionId:sectionId inArticleWithURL:article.url];
    NSString* filePath = [path stringByAppendingPathComponent:@"Section.plist"];
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return [[MWKSection alloc] initWithArticle:article dict:dict];
}

- (NSString*)sectionTextWithId:(NSUInteger)sectionId article:(MWKArticle*)article {
    NSString* path     = [self pathForSectionId:sectionId inArticleWithURL:article.url];
    NSString* filePath = [path stringByAppendingPathComponent:@"Section.html"];

    NSError* err;
    NSString* html = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        return nil;
    }

    return html;
}

- (BOOL)hasHTMLFileForSection:(MWKSection*)section {
    NSString* path     = [self pathForSectionId:section.sectionId inArticleWithURL:section.article.url];
    NSString* filePath = [path stringByAppendingPathComponent:@"Section.html"];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (MWKImage*)imageWithURL:(NSString*)url article:(MWKArticle*)article {
    if (url == nil) {
        return nil;
    }
    NSString* path     = [self pathForImageURL:url forArticleURL:article.url];
    NSString* filePath = [path stringByAppendingPathComponent:@"Image.plist"];
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict) {
        return [[MWKImage alloc] initWithArticle:article dict:dict];
    } else {
        // Not 100% sure if we should return an object here or not,
        // but it seems useful to do so.
        return [[MWKImage alloc] initWithArticle:article sourceURLString:url];
    }
}

- (NSArray*)historyListData {
    NSString* path     = self.basePath;
    NSString* filePath = [path stringByAppendingPathComponent:@"History.plist"];
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return dict[@"entries"];
}

- (NSDictionary*)savedPageListData {
    NSString* path     = self.basePath;
    NSString* filePath = [path stringByAppendingPathComponent:@"SavedPages.plist"];
    return [NSDictionary dictionaryWithContentsOfFile:filePath];
}

- (NSArray*)recentSearchListData {
    NSString* path     = self.basePath;
    NSString* filePath = [path stringByAppendingPathComponent:@"RecentSearches.plist"];
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return dict[@"entries"];
}

- (NSArray<NSURL*>*)cacheRemovalListFromDisk {
    NSString* path      = self.basePath;
    NSString* filePath  = [path stringByAppendingPathComponent:@"TitlesToRemove.plist"];
    NSArray* URLStrings = [NSArray arrayWithContentsOfFile:filePath];
    NSArray<NSURL*>* urls     = [URLStrings wmf_mapAndRejectNil:^NSURL* (id obj) {
        if (obj && [obj isKindOfClass:[NSString class]]) {
            return [NSURL URLWithString:obj];
        } else {
            return nil;
        }
    }];
    return urls;
}

- (BOOL)saveCacheRemovalListToDisk:(NSArray<NSURL*>*)cacheRemovalList error:(NSError**)error {
    NSArray* URLStrings = [cacheRemovalList bk_map:^id (NSURL* obj) {
        return [obj absoluteString];
    }];
    return [self saveArray:URLStrings path:self.basePath name:@"TitlesToRemove.plist" error:error];
}

- (NSArray*)imageInfoForArticleWithURL:(NSURL*)url {
    return [[NSArray arrayWithContentsOfFile:[self pathForImageInfoForArticleWithURL:url]] wmf_mapAndRejectNil:^MWKImageInfo*(id obj) {
        return [MWKImageInfo imageInfoWithExportedData:obj];
    }];
}

#pragma mark - helper methods

- (void)iterateOverArticles:(void (^)(MWKArticle*))block {
    NSFileManager* fm     = [NSFileManager defaultManager];
    NSString* articlePath = [self pathForSites];
    for (NSString* path in [fm enumeratorAtPath:articlePath]) {
        NSArray* components = [path pathComponents];

        //HAX: We make assumptions about the length of paths below.
        //This is due to our title handling assumptions
        //We should remove this when we remove MWKTitle
        if ([components count] < 5) {
            continue;
        }

        NSUInteger count   = [components count];
        NSString* filename = components[count - 1];
        if ([filename isEqualToString:@"Article.plist"]) {
            NSString* dirname   = components[count - 2];
            NSString* titleText = [self stringWithSafeFilename:dirname];

            NSString* language = components[count - 4];
            NSString* domain   = components[count - 5];

            NSURL* url = [NSURL wmf_URLWithDomain:domain language:language title:titleText fragment:nil];

            MWKArticle* article = [self articleWithURL:url];
            block(article);
        }
    }
}

- (void)startCacheRemoval {
    dispatch_async(self.cacheRemovalQueue, ^{
        self.cacheRemovalActive = true;
        [self removeNextArticleFromCacheRemovalList];
    });
}

- (void)stopCacheRemoval {
    dispatch_sync(self.cacheRemovalQueue, ^{
        self.cacheRemovalActive = false;
    });
}

- (void)removeNextArticleFromCacheRemovalList {
    if (!self.cacheRemovalActive) {
        return;
    }
    NSMutableArray<NSURL*>* urlsOfArticlesToRemove = [[self cacheRemovalListFromDisk] mutableCopy];
    if (urlsOfArticlesToRemove.count > 0) {
        NSURL* urlToRemove = urlsOfArticlesToRemove[0];
        MWKArticle* article     = [self articleFromDiskWithURL:urlToRemove];
        [article remove];
        [urlsOfArticlesToRemove removeObjectAtIndex:0];
        NSError* error = nil;
        if ([self saveCacheRemovalListToDisk:urlsOfArticlesToRemove error:&error]) {
            dispatch_async(self.cacheRemovalQueue, ^{ [self removeNextArticleFromCacheRemovalList]; });
        } else {
            DDLogError(@"Error saving cache removal list: %@", error);
        }
    }
}

- (void)removeArticlesWithURLsFromCache:(NSArray<NSURL*>*)urlsToRemove {
    dispatch_async(self.cacheRemovalQueue, ^{
        NSMutableArray<NSURL*>* allURLsToRemove = [[self cacheRemovalListFromDisk] mutableCopy];
        if (allURLsToRemove == nil) {
            allURLsToRemove = [NSMutableArray arrayWithArray:urlsToRemove];
        } else {
            [allURLsToRemove addObjectsFromArray:urlsToRemove];
        }
        NSError* error = nil;
        if (![self saveCacheRemovalListToDisk:allURLsToRemove error:&error]) {
            DDLogError(@"Error saving cache removal list to disk: %@", error);
        }
    });
}

#pragma mark - Deletion

- (NSError*)removeFolderAtBasePath {
    NSError* err;
    [[NSFileManager defaultManager] removeItemAtPath:self.basePath error:&err];
    return err;
}

- (void)deleteArticle:(MWKArticle*)article {
    NSString* path = [self pathForArticle:article];

    // delete article images *before* metadata (otherwise we won't be able to retrieve image lists)
    [[WMFImageController sharedInstance] deleteImagesWithURLs:[[article allImageURLs] allObjects]];

    // delete article metadata last
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

#pragma mark - Cache

- (void)clearMemoryCache {
    [self.articleCache removeAllObjects];
}

@end
