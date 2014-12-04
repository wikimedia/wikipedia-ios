//
//  MWKImageList.m
//  MediaWikiKit
//
//  Created by Brion on 12/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKImageList {
    NSMutableArray *entries;
    NSMutableDictionary *entriesByURL;
    NSMutableDictionary *entriesByNameWithoutSize;
}

-(void)addImageURL:(NSString *)imageURL
{
    [entries addObject:imageURL];
    entriesByURL[imageURL] = imageURL;
    
    NSString *key = [MWKImage fileNameNoSizePrefix:imageURL];
    NSMutableArray *byname = entriesByNameWithoutSize[key];
    if (byname == nil) {
        byname = [[NSMutableArray alloc] init];
        entriesByNameWithoutSize[key] = byname;
    }
    [byname addObject:imageURL];
}

-(NSString *)imageURLAtIndex:(NSUInteger)index
{
    return entries[index];
}

-(BOOL)hasImageURL:(NSString *)imageURL
{
    return (entriesByURL[imageURL] != nil);
}

-(NSUInteger)indexOfImage:(NSString *)imageURL
{
    return [entries indexOfObject:imageURL];
}

-(NSString *)largestImageVariant:(NSString *)imageURL
{
    NSString *baseName = [MWKImage fileNameNoSizePrefix:imageURL];
    NSMutableArray *arr = entriesByNameWithoutSize[baseName];
    
    int width = -1, biggestWidth = -1;
    NSString *biggestURL = imageURL;
    if (arr) {
        for (NSString *sourceURL in arr) {
            NSString *fileName = [sourceURL lastPathComponent];
            int width = [MWKImage fileSizePrefix:fileName];
            if (width > biggestWidth) {
                biggestWidth = width;
                biggestURL = sourceURL;
            }
        }
    }
    return biggestURL;
}

#pragma mark - data i/o

-(instancetype)initWithTitle:(MWKTitle *)title
{
    self = [self initWithSite:title.site];
    if (self) {
        _title = title;
        entries = [[NSMutableArray alloc] init];
        entriesByURL = [[NSMutableDictionary alloc] init];
        entriesByNameWithoutSize = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(instancetype)initWithTitle:(MWKTitle *)title dict:(NSDictionary *)dict
{
    self = [self initWithTitle:title];
    if (self) {
        for (NSString *url in dict[@"entries"]) {
            [self addImageURL:url];
        }
    }
    return self;
}

-(id)dataExport
{
    return @{@"entries": [NSArray arrayWithArray:entries]};
}

@end
