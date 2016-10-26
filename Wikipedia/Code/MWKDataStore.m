#import "YapDatabase+WMFExtensions.h"
#import "YapDatabaseReadWriteTransaction+WMFCustomNotifications.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import "MWKHistoryEntry+WMFDatabaseViews.h"
#import <WMFModel/WMFModel-Swift.h>

#import "WMFRelatedSectionBlackList.h"

NSString *const MWKArticleSavedNotification = @"MWKArticleSavedNotification";
NSString *const MWKArticleKey = @"MWKArticleKey";

NSString *const MWKItemUpdatedNotification = @"MWKItemUpdatedNotification";
NSString *const MWKURLKey = @"MWKURLKey";

NSString *const MWKDataStoreValidImageSitePrefix = @"//upload.wikimedia.org/";

NSString *MWKCreateImageURLWithPath(NSString *path) {
    return [MWKDataStoreValidImageSitePrefix stringByAppendingString:path];
}

static NSString *const MWKImageInfoFilename = @"ImageInfo.plist";

@interface MWKDataStore ()

@property (readwrite, strong, nonatomic) MWKHistoryList *historyList;
@property (readwrite, strong, nonatomic) MWKSavedPageList *savedPageList;
@property (readwrite, strong, nonatomic) MWKRecentSearchList *recentSearchList;
@property (readwrite, strong, nonatomic) WMFRelatedSectionBlackList *blackList;

@property (readwrite, copy, nonatomic) NSString *basePath;
@property (readwrite, strong, nonatomic) NSCache *articleCache;

@property (readwrite, nonatomic, strong) dispatch_queue_t cacheRemovalQueue;
@property (readwrite, nonatomic, getter=isCacheRemovalActive) BOOL cacheRemovalActive;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSOperation *> *articleSaveOperations;
@property (nonatomic, strong) NSOperationQueue *articleSaveQueue;

@end

@implementation MWKDataStore

- (NSOperationQueue *)articleSaveQueue {
    if (!_articleSaveQueue) {
        _articleSaveQueue = [NSOperationQueue new];
        _articleSaveQueue.qualityOfService = NSQualityOfServiceBackground;
        _articleSaveQueue.maxConcurrentOperationCount = 1;
    }
    return _articleSaveQueue;
}

- (NSMutableDictionary<NSString *, NSOperation *> *)articleSaveOperations {
    if (!_articleSaveOperations) {
        _articleSaveOperations = [NSMutableDictionary new];
    }
    return _articleSaveOperations;
}

- (void)asynchronouslyCacheArticle:(MWKArticle *)article {
    [self asynchronouslyCacheArticle:article completion:nil];
}

- (void)asynchronouslyCacheArticle:(MWKArticle *)article completion:(nullable dispatch_block_t)completion {
    NSOperationQueue *queue = [self articleSaveQueue];
    NSMutableDictionary *operations = [self articleSaveOperations];
    @synchronized(queue) {
        NSString *key = article.url.wmf_databaseKey;
        if (!key) {
            return;
        }

        NSOperation *op = operations[key];
        if (op) {
            [op cancel];
            [operations removeObjectForKey:key];
        }

        op = [NSBlockOperation blockOperationWithBlock:^{
            [article save];
            @synchronized(queue) {
                [operations removeObjectForKey:key];
            }
        }];
        op.completionBlock = completion;

        if (!op) {
            return;
        }

        operations[key] = op;

        [queue addOperation:op];
    }
}

- (void)cancelAsynchronousCacheForArticle:(MWKArticle *)article {
    NSOperationQueue *queue = [self articleSaveQueue];
    NSMutableDictionary *operations = [self articleSaveOperations];
    @synchronized(queue) {
        NSString *key = article.url.wmf_databaseKey;
        NSOperation *op = operations[key];
        [op cancel];
        [operations removeObjectForKey:key];
    }
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [self initWithDatabase:[YapDatabase sharedInstance]];
    return self;
}

- (instancetype)initWithDatabase:(YapDatabase *)database {
    self = [self initWithDatabase:database legacyDataBasePath:[[MWKDataStore class] mainDataStorePath]];
    return self;
}

- (instancetype)initWithDatabase:(YapDatabase *)database legacyDataBasePath:(NSString *)basePath {
    self = [super initWithDatabase:database];
    if (self) {
        self.basePath = basePath;
        [self setupLegacyDataStore];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRecievememoryWarningWithNotifcation:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

+ (BOOL)migrateToSharedContainer:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSError *copyError = nil;
    if (![fm copyItemAtPath:[YapDatabase wmf_appSpecificDatabasePath] toPath:[YapDatabase wmf_databasePath] error:&copyError]) {
        if (copyError.code != NSFileNoSuchFileError) {
            if (error) {
                *error = copyError;
            }
            return NO;
        }
    }

    NSError *moveError = nil;
    if (![fm moveItemAtPath:[MWKDataStore appSpecificMainDataStorePath] toPath:[MWKDataStore mainDataStorePath] error:&moveError]) {
        if (moveError.code != NSFileNoSuchFileError) {
            if (error) {
                *error = moveError;
            }
            return NO;
        }
    }

    return YES;
}

#pragma mark - Memory

- (void)didRecievememoryWarningWithNotifcation:(NSNotification *)note {
    [self.articleCache removeAllObjects];
}

#pragma - Accessors

- (MWKHistoryList *)historyList {
    if (!_historyList) {
        _historyList = [[MWKHistoryList alloc] initWithDataStore:self];
    }
    return _historyList;
}

- (MWKSavedPageList *)savedPageList {
    if (!_savedPageList) {
        _savedPageList = [[MWKSavedPageList alloc] initWithDataStore:self];
    }
    return _savedPageList;
}

- (MWKRecentSearchList *)recentSearchList {
    if (!_recentSearchList) {
        _recentSearchList = [[MWKRecentSearchList alloc] initWithDataStore:self];
    }
    return _recentSearchList;
}

- (WMFRelatedSectionBlackList *)blackList {
    if (!_blackList) {
        _blackList = [[WMFRelatedSectionBlackList alloc] initWithDataStore:self];
    }
    return _blackList;
}

#pragma mark - WMFBaseDataStore

- (void)dataStoreWasUpdatedWithNotification:(NSNotification *)notification {

    NSArray<NSString *> *updatedItemKeys = [notification wmf_updatedItemKeys];

    [updatedItemKeys enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSURL *url = [NSURL URLWithString:obj];
        NSAssert(url != nil, @"updated Item with invalid key (should be a URL String)");
        if (url) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MWKItemUpdatedNotification object:self userInfo:@{MWKURLKey: url}];
        }
    }];
}

#pragma mark - Entry Access

- (nullable MWKHistoryEntry *)entryForURL:(NSURL *)url {
    return [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction) {
        MWKHistoryEntry *entry = [transaction objectForKey:[MWKHistoryEntry databaseKeyForURL:url] inCollection:[MWKHistoryEntry databaseCollectionName]];
        return entry;
    }];
}

- (void)enumerateItemsWithBlock:(void (^)(MWKHistoryEntry *_Nonnull entry, BOOL *stop))block {
    NSParameterAssert(block);
    if (!block) {
        return;
    }
    [self readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[MWKHistoryEntry databaseCollectionName]
                                              usingBlock:^(NSString *_Nonnull key, id _Nonnull object, BOOL *_Nonnull stop) {
                                                  block(object, stop);
                                              }];
    }];
}

#pragma mark - Legacy DataStore

+ (NSString *)mainDataStorePath {
    NSString *documentsFolder = [[NSFileManager defaultManager] wmf_containerPath];
    return [documentsFolder stringByAppendingPathComponent:@"Data"];
}

+ (NSString *)appSpecificMainDataStorePath { //deprecated, use the group folder from mainDataStorePath
    NSString *documentsFolder =
        [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [documentsFolder stringByAppendingPathComponent:@"Data"];
}

- (void)setupLegacyDataStore {
    NSString *pathToExclude = [self pathForSites];
    NSError *directoryCreationError = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:pathToExclude withIntermediateDirectories:YES attributes:nil error:&directoryCreationError]) {
        DDLogError(@"Error creating MWKDataStore path: %@", directoryCreationError);
    }
    NSURL *directoryURL = [NSURL fileURLWithPath:pathToExclude isDirectory:YES];
    NSError *excludeBackupError = nil;
    if (![directoryURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&excludeBackupError]) {
        DDLogError(@"Error excluding MWKDataStore path from backup: %@", excludeBackupError);
    }
    self.articleCache = [[NSCache alloc] init];
    self.articleCache.countLimit = 50;
    self.cacheRemovalQueue = dispatch_queue_create("org.wikimedia.cache_removal", DISPATCH_QUEUE_SERIAL);
    dispatch_async(self.cacheRemovalQueue, ^{
        self.cacheRemovalActive = true;
    });
}

#pragma mark - path methods

- (NSString *)joinWithBasePath:(NSString *)path {
    return [self.basePath stringByAppendingPathComponent:path];
}

- (NSString *)pathForSites {
    return [self joinWithBasePath:@"sites"];
}

- (NSString *)pathForDomainInURL:(NSURL *)url {
    NSString *sitesPath = [self pathForSites];
    NSString *domainPath = [sitesPath stringByAppendingPathComponent:url.wmf_domain];
    return [domainPath stringByAppendingPathComponent:url.wmf_language];
}

- (NSString *)pathForArticlesInDomainFromURL:(NSURL *)url {
    NSString *sitePath = [self pathForDomainInURL:url];
    return [sitePath stringByAppendingPathComponent:@"articles"];
}

/// Returns the folder where data for the correspnoding title is stored.
- (NSString *)pathForArticleURL:(NSURL *)url {
    NSString *articlesPath = [self pathForArticlesInDomainFromURL:url];
    NSString *encTitle = [self safeFilenameWithString:url.wmf_titleWithUnderScores];
    return [articlesPath stringByAppendingPathComponent:encTitle];
}

- (NSString *)pathForArticle:(MWKArticle *)article {
    return [self pathForArticleURL:article.url];
}

- (NSString *)pathForSectionsInArticleWithURL:(NSURL *)url {
    NSString *articlePath = [self pathForArticleURL:url];
    return [articlePath stringByAppendingPathComponent:@"sections"];
}

- (NSString *)pathForSectionId:(NSUInteger)sectionId inArticleWithURL:(NSURL *)url {
    NSString *sectionsPath = [self pathForSectionsInArticleWithURL:url];
    NSString *sectionName = [NSString stringWithFormat:@"%d", (int)sectionId];
    return [sectionsPath stringByAppendingPathComponent:sectionName];
}

- (NSString *)pathForSection:(MWKSection *)section {
    return [self pathForSectionId:section.sectionId inArticleWithURL:section.url];
}

- (NSString *)pathForImagesWithArticleURL:(NSURL *)url {
    NSString *articlePath = [self pathForArticleURL:url];
    return [articlePath stringByAppendingPathComponent:@"Images"];
}

- (NSString *)pathForImageURL:(NSString *)imageURL forArticleURL:(NSURL *)articleURL {
    NSString *imagesPath = [self pathForImagesWithArticleURL:articleURL];
    NSString *encURL = [self safeFilenameWithImageURL:imageURL];
    return encURL ? [imagesPath stringByAppendingPathComponent:encURL] : nil;
}

- (NSString *)pathForImage:(MWKImage *)image {
    return [self pathForImageURL:image.sourceURLString forArticleURL:image.article.url];
}

- (NSString *)pathForImageInfoForArticleWithURL:(NSURL *)url {
    return [[self pathForArticleURL:url] stringByAppendingPathComponent:MWKImageInfoFilename];
}

- (NSString *)safeFilenameWithString:(NSString *)str {
    // Escape only % and / with percent style for readability
    NSString *encodedStr = [str stringByReplacingOccurrencesOfString:@"%" withString:@"%25"];
    encodedStr = [encodedStr stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];

    return encodedStr;
}

- (NSString *)stringWithSafeFilename:(NSString *)str {
    return [str stringByRemovingPercentEncoding];
}

- (NSString *)safeFilenameWithImageURL:(NSString *)str {
    str = [str wmf_schemelessURL];

    if (![str hasPrefix:MWKDataStoreValidImageSitePrefix]) {
        return nil;
    }

    NSString *suffix = [str substringFromIndex:[MWKDataStoreValidImageSitePrefix length]];
    NSString *fileName = [suffix lastPathComponent];

    // Image URLs are already percent-encoded, so don't double-encode em.
    // In fact, we want to decode them...
    // If we don't, long Unicode filenames may not fit in the filesystem.
    NSString *decodedFileName = [fileName stringByRemovingPercentEncoding];

    return decodedFileName;
}

#pragma mark - save methods

- (BOOL)ensurePathExists:(NSString *)path error:(NSError **)error {
    return [[NSFileManager defaultManager] createDirectoryAtPath:path
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:error];
}

- (void)ensurePathExists:(NSString *)path {
    [self ensurePathExists:path error:NULL];
}

- (BOOL)saveData:(NSData *)data toFile:(NSString *)filename atPath:(NSString *)path error:(NSError **)error {
    NSAssert([filename length] > 0, @"No file path given for saving data");
    if (!filename) {
        return NO;
    }
    [self ensurePathExists:path error:error];
    NSString *absolutePath = [path stringByAppendingPathComponent:filename];
    return [data writeToFile:absolutePath options:NSDataWritingAtomic error:error];
}

- (void)saveData:(NSData *)data path:(NSString *)path name:(NSString *)name {
    NSError *error = nil;
    [self saveData:data toFile:name atPath:path error:&error];
    NSAssert(error == nil, @"Error saving image to data store: %@", error);
}

- (BOOL)saveArray:(NSArray *)array path:(NSString *)path name:(NSString *)name error:(NSError **)error {
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:array format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    return [self saveData:data toFile:name atPath:path error:error];
}

- (void)saveArray:(NSArray *)array path:(NSString *)path name:(NSString *)name {
    [self saveArray:array path:path name:name error:NULL];
}

- (BOOL)saveDictionary:(NSDictionary *)dict path:(NSString *)path name:(NSString *)name error:(NSError **)error {
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    return [self saveData:data toFile:name atPath:path error:error];
}

- (void)saveDictionary:(NSDictionary *)dict path:(NSString *)path name:(NSString *)name {
    [self saveDictionary:dict path:path name:name error:NULL];
}

- (BOOL)saveString:(NSString *)string path:(NSString *)path name:(NSString *)name error:(NSError **)error {
    return [self saveData:[string dataUsingEncoding:NSUTF8StringEncoding] toFile:name atPath:path error:error];
}

- (void)saveString:(NSString *)string path:(NSString *)path name:(NSString *)name {
    [self saveString:string path:path name:name error:NULL];
}

- (void)saveArticle:(MWKArticle *)article {
    if (article.url.wmf_title == nil) {
        return;
    }
    if ([article isMain]) {
        return;
    }
    if (article.url.wmf_isNonStandardURL) {
        return;
    }

    NSString *path = [self pathForArticle:article];
    NSDictionary *export = [article dataExport];
    [self saveDictionary:export path:path name:@"Article.plist"];
    [self.articleCache setObject:article forKey:article.url];
    dispatchOnMainQueue(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MWKArticleSavedNotification object:self userInfo:@{MWKArticleKey: article}];
    });
}

- (void)saveSection:(MWKSection *)section {
    if ([section.article isMain]) {
        return;
    }
    NSString *path = [self pathForSection:section];
    NSDictionary *export = [section dataExport];
    [self saveDictionary:export path:path name:@"Section.plist"];
}

- (void)saveSectionText:(NSString *)html section:(MWKSection *)section {
    if ([section.article isMain]) {
        return;
    }
    NSString *path = [self pathForSection:section];
    [self saveString:html path:path name:@"Section.html"];
}

- (void)saveImage:(MWKImage *)image {
    if ([image.article isMain]) {
        return;
    }
    NSString *path = [self pathForImage:image];
    NSDictionary *export = [image dataExport];
    [self saveDictionary:export path:path name:@"Image.plist"];
}

- (BOOL)saveRecentSearchList:(MWKRecentSearchList *)list error:(NSError **)error {
    NSString *path = self.basePath;
    NSDictionary *export = @{ @"entries": [list dataExport] };
    return [self saveDictionary:export path:path name:@"RecentSearches.plist" error:error];
}

- (void)saveImageInfo:(NSArray *)imageInfo forArticleURL:(NSURL *)url {
    NSArray *export = [imageInfo bk_map:^id(MWKImageInfo *obj) {
        return [obj dataExport];
    }];

    [self saveArray:export
               path:[self pathForArticleURL:url]
               name:MWKImageInfoFilename];
}

#pragma mark - load methods

- (MWKArticle *)memoryCachedArticleWithURL:(NSURL *)url {
    return [self.articleCache objectForKey:url];
}

- (nullable MWKArticle *)existingArticleWithURL:(NSURL *)url {
    MWKArticle *existingArticle =
        [self memoryCachedArticleWithURL:url] ?: [self articleFromDiskWithURL:url];
    if (existingArticle) {
        [self.articleCache setObject:existingArticle forKey:url];
    }
    return existingArticle;
}

- (MWKArticle *)articleFromDiskWithURL:(NSURL *)url {
    NSString *path = [self pathForArticleURL:url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Article.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (!dict) {
        return nil;
    }
    return [[MWKArticle alloc] initWithURL:url dataStore:self dict:dict];
}

- (MWKArticle *)articleWithURL:(NSURL *)url {
    return [self existingArticleWithURL:url] ?: [[MWKArticle alloc] initWithURL:url dataStore:self];
}

- (MWKSection *)sectionWithId:(NSUInteger)sectionId article:(MWKArticle *)article {
    NSString *path = [self pathForSectionId:sectionId inArticleWithURL:article.url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Section.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return [[MWKSection alloc] initWithArticle:article dict:dict];
}

- (NSString *)sectionTextWithId:(NSUInteger)sectionId article:(MWKArticle *)article {
    NSString *path = [self pathForSectionId:sectionId inArticleWithURL:article.url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Section.html"];

    NSError *err;
    NSString *html = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        return nil;
    }

    return html;
}

- (BOOL)hasHTMLFileForSection:(MWKSection *)section {
    NSString *path = [self pathForSectionId:section.sectionId inArticleWithURL:section.article.url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Section.html"];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (nullable MWKImage *)imageWithURL:(NSString *)url article:(MWKArticle *)article {
    if (url == nil) {
        return nil;
    }
    NSString *path = [self pathForImageURL:url forArticleURL:article.url];
    NSString *filePath = [path stringByAppendingPathComponent:@"Image.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict) {
        return [[MWKImage alloc] initWithArticle:article dict:dict];
    } else {
        // Not 100% sure if we should return an object here or not,
        // but it seems useful to do so.
        return [[MWKImage alloc] initWithArticle:article sourceURLString:url];
    }
}

- (NSArray *)historyListData {
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"History.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return dict[@"entries"];
}

- (NSDictionary *)savedPageListData {
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"SavedPages.plist"];
    return [NSDictionary dictionaryWithContentsOfFile:filePath];
}

- (NSArray *)recentSearchListData {
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"RecentSearches.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return dict[@"entries"];
}

- (NSArray<NSURL *> *)cacheRemovalListFromDisk {
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"TitlesToRemove.plist"];
    NSArray *URLStrings = [NSArray arrayWithContentsOfFile:filePath];
    NSArray<NSURL *> *urls = [URLStrings wmf_mapAndRejectNil:^NSURL *(id obj) {
        if (obj && [obj isKindOfClass:[NSString class]]) {
            return [NSURL URLWithString:obj];
        } else {
            return nil;
        }
    }];
    return urls;
}

- (BOOL)saveCacheRemovalListToDisk:(NSArray<NSURL *> *)cacheRemovalList error:(NSError **)error {
    NSArray *URLStrings = [cacheRemovalList bk_map:^id(NSURL *obj) {
        return [obj absoluteString];
    }];
    return [self saveArray:URLStrings path:self.basePath name:@"TitlesToRemove.plist" error:error];
}

- (NSArray *)imageInfoForArticleWithURL:(NSURL *)url {
    return [[NSArray arrayWithContentsOfFile:[self pathForImageInfoForArticleWithURL:url]] wmf_mapAndRejectNil:^MWKImageInfo *(id obj) {
        return [MWKImageInfo imageInfoWithExportedData:obj];
    }];
}

#pragma mark - helper methods

- (void)iterateOverArticles:(void (^)(MWKArticle *))block {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *articlePath = [self pathForSites];
    for (NSString *path in [fm enumeratorAtPath:articlePath]) {
        NSArray *components = [path pathComponents];

        //HAX: We make assumptions about the length of paths below.
        //This is due to our title handling assumptions
        WMF_TECH_DEBT_TODO(We should remove this when we move to a DB)
        if ([components count] < 5) {
            continue;
        }

        NSUInteger count = [components count];
        NSString *filename = components[count - 1];
        if ([filename isEqualToString:@"Article.plist"]) {
            NSString *dirname = components[count - 2];
            NSString *titleText = [self stringWithSafeFilename:dirname];

            NSString *language = components[count - 4];
            NSString *domain = components[count - 5];

            NSURL *url = [NSURL wmf_URLWithDomain:domain language:language title:titleText fragment:nil];

            MWKArticle *article = [self articleWithURL:url];
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
    NSMutableArray<NSURL *> *urlsOfArticlesToRemove = [[self cacheRemovalListFromDisk] mutableCopy];
    if (urlsOfArticlesToRemove.count > 0) {
        NSURL *urlToRemove = urlsOfArticlesToRemove[0];
        MWKArticle *article = [self articleFromDiskWithURL:urlToRemove];
        [article remove];
        [urlsOfArticlesToRemove removeObjectAtIndex:0];
        NSError *error = nil;
        if ([self saveCacheRemovalListToDisk:urlsOfArticlesToRemove error:&error]) {
            dispatch_async(self.cacheRemovalQueue, ^{
                [self removeNextArticleFromCacheRemovalList];
            });
        } else {
            DDLogError(@"Error saving cache removal list: %@", error);
        }
    }
}

- (void)removeArticlesWithURLsFromCache:(NSArray<NSURL *> *)urlsToRemove {
    dispatch_async(self.cacheRemovalQueue, ^{
        NSMutableArray<NSURL *> *allURLsToRemove = [[self cacheRemovalListFromDisk] mutableCopy];
        if (allURLsToRemove == nil) {
            allURLsToRemove = [NSMutableArray arrayWithArray:urlsToRemove];
        } else {
            [allURLsToRemove addObjectsFromArray:urlsToRemove];
        }
        NSError *error = nil;
        if (![self saveCacheRemovalListToDisk:allURLsToRemove error:&error]) {
            DDLogError(@"Error saving cache removal list to disk: %@", error);
        }
    });
}

- (NSArray *)legacyImageURLsForArticle:(MWKArticle *)article {
    NSString *path = [self pathForArticle:article];
    NSDictionary *legacyImageDictionary = [NSDictionary dictionaryWithContentsOfFile:[path stringByAppendingPathComponent:@"Images.plist"]];
    if ([legacyImageDictionary isKindOfClass:[NSDictionary class]]) {
        NSArray *legacyImageURLStrings = [legacyImageDictionary objectForKey:@"entries"];
        if ([legacyImageURLStrings isKindOfClass:[NSArray class]]) {
            NSArray *legacyImageURLs = [legacyImageURLStrings wmf_mapAndRejectNil:^id(id obj) {
                if ([obj isKindOfClass:[NSString class]]) {
                    return [NSURL URLWithString:obj];
                } else {
                    return nil;
                }
            }];
            return legacyImageURLs;
        }
    }
    return @[];
}

#pragma mark - Deletion

- (NSError *)removeFolderAtBasePath {
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:self.basePath error:&err];
    return err;
}

- (void)deleteArticle:(MWKArticle *)article {
    NSString *path = [self pathForArticle:article];

    [[WMFImageController sharedInstance] deleteImagesWithURLs:[self legacyImageURLsForArticle:article]];

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
