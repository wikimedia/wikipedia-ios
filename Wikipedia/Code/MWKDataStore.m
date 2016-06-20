
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
        self.userDataStore = [[MWKUserDataStore alloc] initWithDataStore:self];
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

- (NSString*)pathForSite:(MWKSite*)site {
    NSString* sitesPath  = [self pathForSites];
    NSString* domainPath = [sitesPath stringByAppendingPathComponent:site.domain];
    return [domainPath stringByAppendingPathComponent:site.language];
}

- (NSString*)pathForArticlesWithSite:(MWKSite*)site {
    NSString* sitePath = [self pathForSite:site];
    return [sitePath stringByAppendingPathComponent:@"articles"];
}

/// Returns the folder where data for the correspnoding title is stored.
- (NSString*)pathForTitle:(MWKTitle*)title {
    NSString* articlesPath = [self pathForArticlesWithSite:title.site];
    NSString* encTitle     = [self safeFilenameWithString:title.dataBaseKey];
    return [articlesPath stringByAppendingPathComponent:encTitle];
}

- (NSString*)pathForArticle:(MWKArticle*)article {
    return [self pathForTitle:article.title];
}

- (NSString*)pathForSectionsWithTitle:(MWKTitle*)title {
    NSString* articlePath = [self pathForTitle:title];
    return [articlePath stringByAppendingPathComponent:@"sections"];
}

- (NSString*)pathForSectionId:(NSUInteger)sectionId title:(MWKTitle*)title {
    NSString* sectionsPath = [self pathForSectionsWithTitle:title];
    NSString* sectionName  = [NSString stringWithFormat:@"%d", (int)sectionId];
    return [sectionsPath stringByAppendingPathComponent:sectionName];
}

- (NSString*)pathForSection:(MWKSection*)section {
    return [self pathForSectionId:section.sectionId title:section.title];
}

- (NSString*)pathForImagesWithTitle:(MWKTitle*)title {
    NSString* articlePath = [self pathForTitle:title];
    return [articlePath stringByAppendingPathComponent:@"Images"];
}

- (NSString*)pathForImageURL:(NSString*)url title:(MWKTitle*)title {
    NSString* imagesPath = [self pathForImagesWithTitle:title];
    NSString* encURL     = [self safeFilenameWithImageURL:url];
    return encURL ? [imagesPath stringByAppendingPathComponent:encURL] : nil;
}

- (NSString*)pathForImage:(MWKImage*)image {
    return [self pathForImageURL:image.sourceURLString title:image.article.title];
}

- (NSString*)pathForTitleImageInfo:(MWKTitle*)title {
    return [[self pathForTitle:title] stringByAppendingPathComponent:MWKImageInfoFilename];
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
    if (article.title.text == nil) {
        return;
    }
    if ([article isMain]) {
        return;
    }
    if ([article.title isNonStandardTitle]) {
        return;
    }

    NSString* path       = [self pathForArticle:article];
    NSDictionary* export = [article dataExport];
    [self saveDictionary:export path:path name:@"Article.plist"];
    [self.articleCache setObject:article forKey:article.title];
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

- (void)saveImageData:(NSData*)data image:(MWKImage*)image {
    if ([image.article isMain]) {
        return;
    }
    NSString* path     = [self pathForImage:image];
    NSString* filename = [@"Image" stringByAppendingPathExtension:image.extension];

    [self saveData:data path:path name:filename];

    [image updateWithData:data];
    [self saveImage:image];
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

- (void)saveImageList:(MWKImageList*)imageList {
    if ([imageList.article isMain]) {
        return;
    }
    NSString* path;
    if (imageList.section) {
        path = [self pathForSection:imageList.section];
    } else {
        path = [self pathForArticle:imageList.article];
    }
    NSDictionary* export = [imageList dataExport];
    [self saveDictionary:export path:path name:@"Images.plist"];
}

- (void)saveImageInfo:(NSArray*)imageInfo forTitle:(MWKTitle*)title {
    [self saveArray:[imageInfo bk_map:^id (MWKImageInfo* obj) { return [obj dataExport]; }]
               path:[self pathForTitle:title]
               name:MWKImageInfoFilename];
}

#pragma mark - load methods

- (MWKArticle*)memoryCachedArticleWithTitle:(MWKTitle*)title {
    return [self.articleCache objectForKey:title];
}

- (MWKArticle*)existingArticleWithTitle:(MWKTitle*)title {
    MWKArticle* existingArticle =
        [self memoryCachedArticleWithTitle:title] ? : [self articleFromDiskWithTitle:title];
    if (existingArticle) {
        [self.articleCache setObject:existingArticle forKey:existingArticle.title];
    }
    return existingArticle;
}

- (MWKArticle*)articleFromDiskWithTitle:(MWKTitle*)title {
    NSString* path     = [self pathForTitle:title];
    NSString* filePath = [path stringByAppendingPathComponent:@"Article.plist"];
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (!dict) {
        return nil;
    }
    return [[MWKArticle alloc] initWithTitle:title dataStore:self dict:dict];
}

- (MWKArticle*)articleWithTitle:(MWKTitle*)title {
    return [self existingArticleWithTitle:title] ? : [[MWKArticle alloc] initWithTitle:title dataStore:self];
}

- (MWKSection*)sectionWithId:(NSUInteger)sectionId article:(MWKArticle*)article {
    NSString* path     = [self pathForSectionId:sectionId title:article.title];
    NSString* filePath = [path stringByAppendingPathComponent:@"Section.plist"];
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return [[MWKSection alloc] initWithArticle:article dict:dict];
}

- (NSString*)sectionTextWithId:(NSUInteger)sectionId article:(MWKArticle*)article {
    NSString* path     = [self pathForSectionId:sectionId title:article.title];
    NSString* filePath = [path stringByAppendingPathComponent:@"Section.html"];

    NSError* err;
    NSString* html = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        return nil;
    }

    return html;
}

- (BOOL)hasHTMLFileForSection:(MWKSection*)section {
    NSString* path     = [self pathForSectionId:section.sectionId title:section.title];
    NSString* filePath = [path stringByAppendingPathComponent:@"Section.html"];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (MWKImage*)imageWithURL:(NSString*)url article:(MWKArticle*)article {
    if (url == nil) {
        return nil;
    }
    NSString* path     = [self pathForImageURL:url title:article.title];
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

- (NSString*)pathForImageData:(MWKImage*)image {
    return [self pathForImageData:image.sourceURLString title:image.article.title];
}

- (NSString*)pathForImageData:(NSString*)sourceURL title:(MWKTitle*)title {
    NSString* path     = [self pathForImageURL:sourceURL title:title];
    NSString* fileName = [@"Image" stringByAppendingPathExtension:sourceURL.pathExtension];
    return [path stringByAppendingPathComponent:fileName];
}

- (NSData*)imageDataWithImage:(MWKImage*)image {
    if (image == nil) {
        NSLog(@"nil image passed to imageDataWithImage");
        return nil;
    }
    NSString* filePath = [self pathForImageData:image];

    NSError* err;
    NSData* data = [NSData dataWithContentsOfFile:filePath options:0 error:&err];
    if (err) {
        NSLog(@"Failed to load image from %@: %@", filePath, [err description]);
        return nil;
    }
    return data;
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

- (NSArray*)imageInfoForTitle:(MWKTitle*)title {
    return [[NSArray arrayWithContentsOfFile:[self pathForTitleImageInfo:title]] bk_map:^MWKImageInfo*(id obj) {
        return [MWKImageInfo imageInfoWithExportedData:obj];
    }];
}

#pragma mark - helper methods

- (MWKImageList*)imageListWithArticle:(MWKArticle*)article section:(MWKSection*)section {
    NSString* path;
    if (section) {
        path = [self pathForSection:section];
    } else {
        path = [self pathForArticle:article];
    }
    NSString* filePath = [path stringByAppendingPathComponent:@"Images.plist"];
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict) {
        return [[MWKImageList alloc] initWithArticle:article section:section dict:dict];
    } else {
        return [[MWKImageList alloc] initWithArticle:article section:section];
    }
}

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

            MWKSite* site   = [[MWKSite alloc] initWithDomain:domain language:language];
            MWKTitle* title = [site titleWithString:titleText];

            MWKArticle* article = [self articleWithTitle:title];
            block(article);
        }
    }
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
    [[WMFImageController sharedInstance] deleteImagesWithURLs:[article.allImageURLs allObjects]];

    // delete article metadata last
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

#pragma mark - Cache

- (void)clearMemoryCache {
    [self.articleCache removeAllObjects];
}

@end
