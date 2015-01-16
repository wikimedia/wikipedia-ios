//
//  MWKImageMetadata.m
//  MediaWikiKit
//
//  Created by Brion on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKImageMetadata {
    NSDictionary *_extmetadata;
}

-(instancetype)initWithArticle:(MWKArticle *)article name:(NSString *)name
{
    self = [self initWithSite:article.site];
    if (self) {
        _article = article;
        _name = name;
        _extmetadata = @{};
    }
    return self;
}

-(instancetype)initWithArticle:(MWKArticle *)article name:(NSString *)name dict:(NSDictionary *)dict
{
    self = [self initWithArticle:article name:name];
    if (self) {
        _extmetadata = [self parseImageMetadata:dict];
    }
    return self;
}

-(NSDictionary *)parseImageMetadata:(NSDictionary *)dict
{
    NSArray *imageinfos = dict[@"imageinfo"];
    if (imageinfos == nil || [imageinfos count] == 0) {
        return @{};
    }
    
    NSDictionary *imageinfo = imageinfos[0];
    NSMutableDictionary *outdict = [[NSMutableDictionary alloc] init];
    for (NSString *key in [imageinfo keyEnumerator]) {
        outdict[key] = [[MWKImageMetadataItem alloc] initWithDict:imageinfo[key]];
    }
    return [NSDictionary dictionaryWithDictionary:outdict];
}

-(NSDictionary *)dataExport
{
    NSMutableDictionary *fields = [[NSMutableDictionary alloc] init];
    for (NSString *key in [self.extmetadata keyEnumerator]) {
        MWKImageMetadataItem *item = self.extmetadata[key];
        fields[key] = [item dataExport];
    }
    return @{@"imageinfo": @[fields]};
}

#pragma mark - io methods

-(void)save
{
    [self.article.dataStore saveImageMetadata:self];
}

-(NSString *)basePath
{
    NSString *articlePath = [self.article.dataStore pathForArticle:self.article];
    NSString *metaPath = [articlePath stringByAppendingPathComponent:@"ImageMetadata"];

    // note: names are validated server-side. scary!
    return [metaPath stringByAppendingPathComponent:self.name];
}

-(void)remove
{
    NSString *path = [self.article.dataStore pathForImageMetadata:self];

    NSError *err = nil;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&err];
    
    if (err) {
        NSLog(@"err deleting image metadata: %@", err);
    }
}

#pragma mark - convenience properties

-(NSString *)license
{
    MWKImageMetadataItem *item = self.extmetadata[@"License"];
    return item ? item.value : @"";
}

-(NSString *)licenseShortName
{
    MWKImageMetadataItem *item = self.extmetadata[@"LicenseShortName"];
    return item ? item.value : @"";
}

-(NSString *)licenseUrl
{
    MWKImageMetadataItem *item = self.extmetadata[@"LicenseUrl"];
    return item ? item.value : @"";
}

-(NSString *)artist
{
    MWKImageMetadataItem *item = self.extmetadata[@"Artist"];
    return item ? item.value : @"";
}

-(NSString *)imageDescription
{
    MWKImageMetadataItem *item = self.extmetadata[@"ImageDescription"];
    return item ? item.value : @"";
}

@end
