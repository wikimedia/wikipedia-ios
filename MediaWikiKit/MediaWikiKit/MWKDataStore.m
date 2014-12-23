//
//  MWKDataStore.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKDataStore

-(instancetype)initWithBasePath:(NSString *)basePath
{
    self = [self init];
    if (self) {
        _basePath = [basePath copy];
    }
    return self;
}

#pragma mark - path methods

-(NSString *)pathForPath:(NSString *)path
{
    return [self.basePath stringByAppendingPathComponent:path];
}

-(NSString *)pathForSites
{
    return [self pathForPath:@"sites"];
}

-(NSString *)pathForSite:(MWKSite *)site
{
    NSString *sitesPath = [self pathForSites];
    NSString *domainPath = [sitesPath stringByAppendingPathComponent:site.domain];
    return [domainPath stringByAppendingPathComponent:site.language];
}

-(NSString *)pathForArticlesWithSite:(MWKSite *)site
{
    NSString *sitePath = [self pathForSite:site];
    return [sitePath stringByAppendingPathComponent:@"articles"];
}

-(NSString *)pathForTitle:(MWKTitle *)title
{
    NSString *articlesPath = [self pathForArticlesWithSite:title.site];
    NSString *encTitle = [self safeFilenameWithString:title.prefixedDBKey];
    return [articlesPath stringByAppendingPathComponent:encTitle];
}

-(NSString *)pathForArticle:(MWKArticle *)article
{
    return [self pathForTitle:article.title];
}

-(NSString *)pathForSectionsWithTitle:(MWKTitle *)title
{
    NSString *articlePath = [self pathForTitle:title];
    return [articlePath stringByAppendingPathComponent:@"sections"];
}

-(NSString *)pathForSectionId:(NSUInteger)sectionId title:(MWKTitle *)title
{
    NSString *sectionsPath = [self pathForSectionsWithTitle:title];
    NSString *sectionName = [NSString stringWithFormat:@"%d", (int)sectionId];
    return [sectionsPath stringByAppendingPathComponent:sectionName];
}

-(NSString *)pathForSection:(MWKSection *)section
{
    return [self pathForSectionId:section.sectionId title:section.title];
}

-(NSString *)pathForImagesWithTitle:(MWKTitle *)title
{
    NSString *articlePath = [self pathForTitle:title];
    return [articlePath stringByAppendingPathComponent:@"Images"];
}

-(NSString *)pathForImageURL:(NSString *)url title:(MWKTitle *)title
{
    NSString *imagesPath = [self pathForImagesWithTitle:title];
    NSString *encURL = [self safeFilenameWithImageURL:url];
    return [imagesPath stringByAppendingPathComponent:encURL];
}

-(NSString *)pathForImage:(MWKImage *)image
{
    return [self pathForImageURL:image.sourceURL title:image.article.title];
}

-(NSString *)safeFilenameWithString:(NSString *)str
{
    // This handy function does most of the percent-escaping
    NSString *encodedStr = [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    // But it leaves "/" and "&" intact. Naughty!
    encodedStr = [encodedStr stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    encodedStr = [encodedStr stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];

    return encodedStr;
}

-(NSString *)stringWithSafeFilename:(NSString *)str
{
    return [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

-(NSString *)safeFilenameWithImageURL:(NSString *)str
{
    if ([str hasPrefix:@"http:"]) {
        str = [str substringFromIndex:[@"http:" length]];
    }
    if ([str hasPrefix:@"https:"]) {
        str = [str substringFromIndex:[@"https:" length]];
    }
    NSString *prefix = @"//upload.wikimedia.org/";
    if ([str hasPrefix:prefix]) {
        NSString *suffix = [str substringFromIndex:[prefix length]];

        // Image URLs are already percent-encoded, so don't double-encode em.

        // "/" occurs in those nasty paths! but ":" cannot so let's use it
        // just like Mac OS X does ;)
        //NSString *noslashes = [suffix stringByReplacingOccurrencesOfString:@"/" withString:@":"];
        
        NSString *fileName = [suffix lastPathComponent];
        return fileName;
    } else {
        @throw [NSException exceptionWithName:@"MWKDataStoreException"
                                       reason:@"Tried to save non-upload.wikimedia.org URL as image"
                                     userInfo:@{@"str": str ? str : [NSNull null]}];
    }
    
}

#pragma mark - save methods

-(void)ensurePathExists:(NSString *)path
{
    NSError *err;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&err];
    if (err) {
        @throw [NSException exceptionWithName:@"MWKDataStoreException"
                                       reason:@"path creation failure"
                                     userInfo:@{@"path": path, @"error": err}];
    }
}

-(void)saveDictionary:(NSDictionary *)dict path:(NSString *)path name:(NSString *)name
{
    [self ensurePathExists:path];
    
    NSString *filePath = [path stringByAppendingPathComponent:name];
    if (![dict writeToFile:filePath atomically:YES]) {
        @throw [NSException exceptionWithName:@"MWKDataStoreException"
                                       reason:@"dictionary file atomic write failure"
                                     userInfo:@{@"filePath": filePath}];
    }
}

-(void)saveString:(NSString *)string path:(NSString *)path name:(NSString *)name
{
    [self ensurePathExists:path];
    
    NSError *err;
    NSString *filePath = [path stringByAppendingPathComponent:name];
    if (![string writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        if (err) {
            @throw [NSException exceptionWithName:@"MWKDataStoreException"
                                           reason:[err description]
                                         userInfo:@{@"filePath": filePath, @"err": err}];
        } else {
            @throw [NSException exceptionWithName:@"MWKDataStoreException"
                                           reason:@"string file atomic write failure"
                                         userInfo:@{@"filePath": filePath}];
        }
    }
}

-(void)saveData:(NSData *)data path:(NSString *)path name:(NSString *)name
{
    [self ensurePathExists:path];
    
    NSError *err;
    NSString *filePath = [path stringByAppendingPathComponent:name];
    if (![data writeToFile:filePath options:NSDataWritingAtomic error:&err]) {
        if (err) {
            @throw [NSException exceptionWithName:@"MWKDataStoreException"
                                           reason:[err description]
                                         userInfo:@{@"filePath": filePath, @"err": err}];
        } else {
            @throw [NSException exceptionWithName:@"MWKDataStoreException"
                                           reason:@"data file atomic write failure"
                                         userInfo:@{@"filePath": filePath}];
        }
    }
}

-(void)saveArticle:(MWKArticle *)article
{
    NSString *path = [self pathForArticle:article];
    NSDictionary *export = [article dataExport];
    [self saveDictionary:export path:path name:@"Article.plist"];
}

-(void)saveSection:(MWKSection *)section
{
    NSString *path = [self pathForSection:section];
    NSDictionary *export = [section dataExport];
    [self saveDictionary:export path:path name:@"Section.plist"];
}

-(void)saveSectionText:(NSString *)html section:(MWKSection *)section
{
    NSString *path = [self pathForSection:section];
    [self saveString:html path:path name:@"Section.html"];
}

-(void)saveImage:(MWKImage *)image
{
    NSString *path = [self pathForImage:image];
    NSDictionary *export = [image dataExport];
    [self saveDictionary:export path:path name:@"Image.plist"];
}

-(void)saveImageData:(NSData *)data image:(MWKImage *)image
{
    NSString *path = [self pathForImage:image];
    NSString *filename = [@"Image" stringByAppendingPathExtension:image.extension];
    [self saveData:data path:path name:filename];
    
    [image updateWithData:data];
    [self saveImage:image];
}

-(void)saveHistoryList:(MWKHistoryList *)list
{
    NSString *path = self.basePath;
    NSDictionary *export = [list dataExport];
    [self saveDictionary:export path:path name:@"History.plist"];
}

-(void)saveSavedPageList:(MWKSavedPageList *)list
{
    NSString *path = self.basePath;
    NSDictionary *export = [list dataExport];
    [self saveDictionary:export path:path name:@"SavedPages.plist"];
}

-(void)saveRecentSearchList:(MWKRecentSearchList *)list
{
    NSString *path = self.basePath;
    NSDictionary *export = [list dataExport];
    [self saveDictionary:export path:path name:@"RecentSearches.plist"];
}

-(void)saveImageList:(MWKImageList *)imageList
{
    NSString *path;
    if (imageList.section) {
        path = [self pathForSection:imageList.section];
    } else {
        path = [self pathForArticle:imageList.article];
    }
    NSDictionary *export = [imageList dataExport];
    [self saveDictionary:export path:path name:@"Images.plist"];
}

#pragma mark - load methods

/// May return nil if no article data available.
-(MWKArticle *)articleWithTitle:(MWKTitle *)title
{
    NSString *path = [self pathForTitle:title];
    NSString *filePath = [path stringByAppendingPathComponent:@"Article.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict == nil) {
        return [[MWKArticle alloc] initWithTitle:title dataStore:self];
    } else {
        return [[MWKArticle alloc] initWithTitle:title dataStore:self dict:dict];
    }
}

-(MWKSection *)sectionWithId:(NSUInteger)sectionId article:(MWKArticle *)article
{
    NSString *path = [self pathForSectionId:sectionId title:article.title];
    NSString *filePath = [path stringByAppendingPathComponent:@"Section.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return [[MWKSection alloc] initWithArticle:article dict:dict];
}

-(NSString *)sectionTextWithId:(NSUInteger)sectionId article:(MWKArticle *)article
{
    NSString *path = [self pathForSectionId:sectionId title:article.title];
    NSString *filePath = [path stringByAppendingPathComponent:@"Section.html"];
    
    NSError *err;
    NSString *html = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        @throw [NSException exceptionWithName:@"MWKDataStoreException"
                                       reason:err.description
                                     userInfo:@{@"filePath": filePath, @"err": err}];
    }

    return html;
}

-(MWKImage *)imageWithURL:(NSString *)url article:(MWKArticle *)article
{
    if (url == nil) {
        return nil;
    }
    NSString *path = [self pathForImageURL:url title:article.title];
    NSString *filePath = [path stringByAppendingPathComponent:@"Image.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict) {
        return [[MWKImage alloc] initWithArticle:article dict:dict];
    } else {
        return nil;
    }
}

-(NSData *)imageDataWithImage:(MWKImage *)image
{
    if (image == nil) {
        NSLog(@"nil image passed to imageDataWithImage");
        return nil;
    }
    NSString *path = [self pathForImage:image];
    NSString *fileName = [@"Image" stringByAppendingPathExtension:image.extension];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];

    NSError *err;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&err];
    if (err) {
        NSLog(@"Failed to load image from %@: %@", filePath,[err description]);
        return nil;
    }
    return data;
}

-(MWKHistoryList *)historyList
{
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"History.plist"];
    
    NSDictionary *dict =[NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict) {
        return [[MWKHistoryList alloc] initWithDict:dict];
    } else {
        return nil;
    }
}

-(MWKSavedPageList *)savedPageList
{
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"SavedPages.plist"];
    
    NSDictionary *dict =[NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict) {
        return [[MWKSavedPageList alloc] initWithDict:dict];
    } else {
        return nil;
    }
}

-(MWKRecentSearchList *)recentSearchList
{
    NSString *path = self.basePath;
    NSString *filePath = [path stringByAppendingPathComponent:@"RecentSearches.plist"];
    
    NSDictionary *dict =[NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict) {
        return [[MWKRecentSearchList alloc] initWithDict:dict];
    } else {
        return nil;
    }
}



#pragma mark - helper methods

-(MWKUserDataStore *)userDataStore
{
    return [[MWKUserDataStore alloc] initWithDataStore:self];
}


-(MWKImageList *)imageListWithArticle:(MWKArticle *)article section:(MWKSection *)section
{
    NSString *path;
    if (section) {
        path = [self pathForSection:section];
    } else {
        path = [self pathForArticle:article];
    }
    NSString *filePath = [path stringByAppendingPathComponent:@"Images.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (dict) {
        return [[MWKImageList alloc] initWithArticle:article section:section dict:dict];
    } else {
        return [[MWKImageList alloc] initWithArticle:article section:section];
    }
}

-(void)iterateOverArticles:(void(^)(MWKArticle *))block
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *articlePath = [self pathForSites];
    for (NSString *path in [fm enumeratorAtPath:articlePath]) {
        NSArray *components = [path pathComponents];
        NSUInteger count = [components count];
        NSString *filename = components[count - 1];
        if ([filename isEqualToString:@"Article.plist"]) {
            NSString *dirname = components[count - 2];
            NSString *titleText = [self stringWithSafeFilename:dirname];

            NSString *language = components[count - 4];
            NSString *domain = components[count - 5];
            
            MWKSite *site = [[MWKSite alloc] initWithDomain:domain language:language];
            MWKTitle *title = [site titleWithString:titleText];
            
            MWKArticle *article = [self articleWithTitle:title];
            block(article);
        }
    }
}

@end
