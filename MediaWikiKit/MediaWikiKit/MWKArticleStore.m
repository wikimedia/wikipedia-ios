//
//  MWKArticleFetcher.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKArticleStore {
    MWKArticle *_article;
    NSArray *_sections;
}

-(instancetype)initWithTitle:(MWKTitle *)title dataStore:(MWKDataStore *)dataStore;
{
    self = [self init];
    if (self) {
        if (title == nil) {
            @throw [NSException exceptionWithName:@"MWArticleStoreException"
                                           reason:@"invalid input, title is nil"
                                         userInfo:nil];
        }
        if (dataStore == nil) {
            @throw [NSException exceptionWithName:@"MWArticleStoreException"
                                           reason:@"invalid input, dataStore is nil"
                                         userInfo:nil];
        }
        _title = title;
        _dataStore = dataStore;
        _article = nil;
        _sections = nil;
    }
    return self;
}

-(MWKArticle *)importMobileViewJSON:(NSDictionary *)dict
{
    NSDictionary *mobileview = dict[@"mobileview"];
    if (!mobileview || ![mobileview isKindOfClass:[NSDictionary class]]) {
        @throw [NSException exceptionWithName:@"MWArticleStoreException"
                                       reason:@"invalid input, not a mobileview api data"
                                     userInfo:nil];
    }

    // Populate article metadata
    _article = [[MWKArticle alloc] initWithTitle:_title dict:mobileview];
    
    // Populate sections
    NSArray *sectionsData = mobileview[@"sections"];
    if (!sectionsData || ![sectionsData isKindOfClass:[NSArray class]]) {
        @throw [NSException exceptionWithName:@"MWArticleStoreException"
                                       reason:@"invalid input, sections missing or not an array"
                                     userInfo:nil];
    }
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:[sectionsData count]];
    for (NSDictionary *sectionData in sectionsData) {
        MWKSection *section = [[MWKSection alloc] initWithArticle:self.article dict:sectionData];
        [sections addObject:section];
        [self.dataStore saveSection:section];
        if (sectionData[@"text"]) {
            [self.dataStore saveSectionText:sectionData[@"text"] section:section];
        }
    }
    //if (_sections == nil) {
    //    _sections = [NSArray arrayWithArray:sections];
    //}

    [self.dataStore saveArticle:self.article];
    
    return self.article;
}

#pragma mark - getters

-(MWKArticle *)article
{
    if (!_article) {
        @try {
            _article = [self.dataStore articleWithTitle:self.title];
        }
        @catch (NSException *e) {
            NSLog(@"Exception loading article: %@", e);
        }
    }
    return _article;
}

-(NSArray *)sections
{
    static NSString *prefix = @"section";
    if (_sections == nil) {
        NSMutableArray *array = [@[] mutableCopy];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *path = [[self.dataStore pathForTitle:self.title] stringByAppendingPathComponent:@"sections"];
        NSArray *files = [fm contentsOfDirectoryAtPath:path error:nil];
        files = [files sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            NSString *suffix1 = [obj1 substringFromIndex:[prefix length]];
            int sectionId1 = [suffix1 intValue];
            NSString *suffix2 = [obj2 substringFromIndex:[prefix length]];
            int sectionId2 = [suffix2 intValue];
            if (sectionId1 < sectionId2) {
                return NSOrderedAscending;
            } else if (sectionId1 == sectionId2) {
                return NSOrderedSame;
            } else {
                return NSOrderedDescending;
            }
        }];
        for (NSString *subpath in files) {
            NSString *filename = [subpath lastPathComponent];
            NSLog(@"qqq %@", filename);
            if ([filename hasPrefix:prefix]) {
                NSString *suffix = [filename substringFromIndex:[prefix length]];
                int sectionId = [suffix intValue];
                array[sectionId] = [self sectionAtIndex:sectionId];
            }
        }
        _sections = [NSArray arrayWithArray:array];
    }
    return _sections;
}

-(MWKSection *)sectionAtIndex:(NSUInteger)index
{
    if (_sections) {
        return _sections[index];
    } else {
        return [self.dataStore sectionWithId:index article:self.article];
    }
}

-(NSString *)sectionTextAtIndex:(NSUInteger)index
{
    return [self.dataStore sectionTextWithId:index article:self.article];
}

-(NSArray *)imageURLs
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    // @fixme implement
    
    return [NSArray arrayWithArray:array];
}

-(MWKImage *)imageWithURL:(NSString *)url
{
    return [self.dataStore imageWithURL:url title:self.title];
}

-(MWKImage *)importImageURL:(NSString *)url
{
    return [[MWKImage alloc] initWithTitle:self.title sourceURL:url];
}

-(NSData *)imageDataWithImage:(MWKImage *)image
{
    return [self.dataStore imageDataWithImage:image];
}

-(UIImage *)UIImageWithImage:(MWKImage *)image
{
    NSData *data = [self imageDataWithImage:image];
    if (data) {
        return [UIImage imageWithData:data];
    } else {
        return nil;
    }
}

-(MWKImage *)importImageData:(NSData *)data image:(MWKImage *)image mimeType:(NSString *)mimeType
{
    [self.dataStore saveImageData:data image:image mimeType:mimeType];
    return image;
}


-(void)setNeedsRefresh:(BOOL)val
{
    NSString *payload = @"needsRefresh";
    NSString *filePath = [self.dataStore pathForArticle:self.article];
    NSString *fileName = [filePath stringByAppendingPathComponent:@"needsRefresh.lock"];
    [payload writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(BOOL)needsRefresh
{
    NSString *filePath = [self.dataStore pathForArticle:self.article];
    NSString *fileName = [filePath stringByAppendingPathComponent:@"needsRefresh.lock"];
    return [[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:nil];
}

-(void)remove
{
    NSString *path = [self.dataStore pathForArticle:self.article];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end
