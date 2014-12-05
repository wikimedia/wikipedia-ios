//
//  MWKImageList.m
//  MediaWikiKit
//
//  Created by Brion on 12/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKImageList {
    NSMutableDictionary *entriesBySection;
    NSMutableDictionary *entriesByURL;
    NSMutableDictionary *entriesByNameWithoutSize;
}

-(NSMutableArray *)entriesBySection:(int)sectionId
{
    id key = [@(sectionId) stringValue];
    NSMutableArray *entries = entriesBySection[key];
    if (entries == nil) {
        entries = [[NSMutableArray alloc] init];
        entriesBySection[key] = entries;
    }
    return entries;
}

-(void)addImageURL:(NSString *)imageURL sectionId:(int)sectionId
{
    NSMutableArray *entries = [self entriesBySection:sectionId];
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

-(NSString *)imageURLAtIndex:(NSUInteger)index sectionId:(int)sectionId
{
    NSMutableArray *entries = [self entriesBySection:sectionId];
    if (index < [entries count]) {
        return entries[index];
    } else {
        return nil;
    }
}

-(BOOL)hasImageURL:(NSString *)imageURL
{
    return (entriesByURL[imageURL] != nil);
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
            width = [MWKImage fileSizePrefix:fileName];
            NSLog(@"%@ is %d", fileName, width);
            if (width > biggestWidth) {
                biggestWidth = width;
                biggestURL = sourceURL;
            }
        }
    } else {
        NSLog(@"no variants for %@", baseName);
    }
    return biggestURL;
}

-(NSArray *)imageURLsForSectionId:(int)sectionId
{
    return [[self entriesBySection:sectionId] copy];
}

-(NSArray *)imagesBySection
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSArray *keys = [entriesBySection keysSortedByValueUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
        int int1 = [key1 intValue];
        int int2 = [key2 intValue];
        if (int1 == int2 ) {
            return NSOrderedSame;
        } else if (int1 > int2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedAscending;
        }
    }];
    int lastSection = -1;
    for (NSString *key in keys) {
        lastSection = [key intValue];
    }
    for (int i = 0; i <= lastSection; i++) {
        NSString *key = [NSString stringWithFormat:@"%d", i];
        NSMutableArray *subarr = [[NSMutableArray alloc] init];
        for (NSString *url in entriesBySection[key]) {
            [subarr addObject:url];
        }
        [arr addObject:subarr];
    }
    return [NSArray arrayWithArray:arr];
}


#pragma mark - data i/o

-(instancetype)initWithTitle:(MWKTitle *)title
{
    self = [self initWithSite:title.site];
    if (self) {
        _title = title;
        entriesBySection = [[NSMutableDictionary alloc] init];
        entriesByURL = [[NSMutableDictionary alloc] init];
        entriesByNameWithoutSize = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(instancetype)initWithTitle:(MWKTitle *)title dict:(NSDictionary *)dict
{
    self = [self initWithTitle:title];
    if (self) {
        for (NSNumber *key in [dict allKeys]) {
            for (NSString *url in dict[key]) {
                [self addImageURL:url sectionId:[key intValue]];
            }
        }
    }
    return self;
}

-(id)dataExport
{
    return [NSDictionary dictionaryWithDictionary:entriesBySection];
}

@end
