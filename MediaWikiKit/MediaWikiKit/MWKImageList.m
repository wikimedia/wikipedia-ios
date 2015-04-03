//
//  MWKImageList.m
//  MediaWikiKit
//
//  Created by Brion on 12/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import "NSString+Extras.h"

@implementation MWKImageList {
    NSMutableArray* entries;
    NSMutableDictionary* entriesByURL;
    NSMutableDictionary* entriesByNameWithoutSize;
    unsigned long mutationState;
}

- (instancetype)initWithSite:(MWKSite*)site {
    self = [super initWithSite:site];
    if (self) {
        entries                  = [[NSMutableArray alloc] init];
        mutationState            = 0;
        entriesByURL             = [[NSMutableDictionary alloc] init];
        entriesByNameWithoutSize = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithArticle:(MWKArticle*)article section:(MWKSection*)section {
    self = [self initWithSite:section.site];
    if (self) {
        _article = article;
        _section = section;
    }
    return self;
}

- (instancetype)initWithArticle:(MWKArticle*)article section:(MWKSection*)section dict:(NSDictionary*)dict {
    self = [self initWithArticle:article section:section];
    if (self) {
        for (NSString* url in dict[@"entries"]) {
            [self addImageURL:url];
        }
    }
    return self;
}

- (void)addImageURL:(NSString*)imageURL {
    imageURL = [imageURL getUrlWithoutScheme];

    [entries addObject:imageURL];
    entriesByURL[imageURL] = imageURL;

    NSString* key          = [MWKImage fileNameNoSizePrefix:imageURL];
    NSMutableArray* byname = entriesByNameWithoutSize[key];
    if (byname == nil) {
        byname                        = [[NSMutableArray alloc] init];
        entriesByNameWithoutSize[key] = byname;
    }
    [byname addObject:imageURL];
    mutationState++;
}

- (NSUInteger)count {
    return [entries count];
}

- (NSString*)imageURLAtIndex:(NSUInteger)index {
    if (index < [entries count]) {
        return entries[index];
    } else {
        return nil;
    }
}

- (MWKImage*)objectAtIndexedSubscript:(NSUInteger)index {
    NSString* imageURL = [self imageURLAtIndex:index];
    return [self.article.dataStore imageWithURL:imageURL article:self.article];
}

- (BOOL)hasImageURL:(NSString*)imageURL {
    return [self imageWithURL:imageURL] != nil;
}

- (MWKImage*)imageWithURL:(NSString*)imageURL {
    return [self.article imageWithURL:imageURL];
}

- (NSArray*)imageSizeVariants:(NSString*)imageURL {
    if (imageURL == nil) {
        return nil;
    }
    NSString* baseName  = [MWKImage fileNameNoSizePrefix:imageURL];
    NSMutableArray* arr = entriesByNameWithoutSize[baseName];

    if (arr) {
        NSMutableArray* arr2 = [NSMutableArray arrayWithArray:arr];
        [arr2 sortUsingComparator:^NSComparisonResult (NSString* url1, NSString* url2) {
#warning TODO(mhurd): add tests for this, be sure to cover fileSizePrefix returning NSNotFound

            NSInteger width1 = [MWKImage fileSizePrefix:[url1 lastPathComponent]];
            NSInteger width2 = [MWKImage fileSizePrefix:[url2 lastPathComponent]];

            if (width1 > width2) {
                return NSOrderedDescending;
            } else if (width1 < width2) {
                return NSOrderedAscending;
            } else {
                return NSOrderedSame;
            }
        }];
        return arr2;
    } else {
        NSLog(@"no variants for %@", baseName);
        return @[];
    }
}

- (NSString*)largestImageVariant:(NSString*)imageURL {
    return [self largestImageVariantForURL:imageURL].sourceURL;
}

- (NSString*)smallestImageVariant:(NSString*)imageURL {
    return [self smallestImageVariantForURL:imageURL].sourceURL;
}

- (MWKImage*)largestImageVariantForURL:(NSString*)imageURL cachedOnly:(BOOL)cachedOnly {
    NSArray* arr = [self imageSizeVariants:imageURL];
    for (NSString* variantURL in [arr reverseObjectEnumerator]) {
        MWKImage* image = [self.article imageWithURL:variantURL];
        if (!cachedOnly || image.isCached) {
            return image;
        }
    }
    return nil;
}

- (MWKImage*)smallestImageVariantForURL:(NSString*)imageURL cachedOnly:(BOOL)cachedOnly {
    NSArray* arr = [self imageSizeVariants:imageURL];
    for (NSString* variantURL in arr) {
        MWKImage* image = [self.article imageWithURL:variantURL];
        if (!cachedOnly || image.isCached) {
            return image;
        }
    }
    return nil;
}

- (MWKImage*)largestImageVariantForURL:(NSString*)imageURL {
    return [self largestImageVariantForURL:imageURL cachedOnly:YES];
}

- (MWKImage*)smallestImageVariantForURL:(NSString*)imageURL {
    return [self smallestImageVariantForURL:imageURL cachedOnly:YES];
}

- (NSUInteger)indexOfImage:(MWKImage*)image {
    return [entries indexOfObject:image.sourceURL];
}

- (BOOL)containsImage:(MWKImage*)image {
    return [entries containsObject:image.sourceURL];
}

- (NSArray*)uniqueLargestVariants {
    if (!entries || entries.count == 0) {
        return nil;
    }
    NSMutableOrderedSet* resultBuilder = [[NSMutableOrderedSet alloc] initWithCapacity:entries.count];
    for (NSString* sourceURL in entries) {
        MWKImage* image = [self largestImageVariantForURL:sourceURL cachedOnly:NO];
        NSAssert(image, @"Couldn't retrieve image record for image list entry: %@", sourceURL);
        [resultBuilder addObject:image];
    }
    return [resultBuilder array];
}

- (BOOL)addImageURLIfAbsent:(NSString*)imageURL {
    if (imageURL && imageURL.length > 0 && ![entries containsObject:imageURL]) {
        [self addImageURL:imageURL];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - data i/o

- (id)dataExport {
    return @{@"entries": entries};
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state
                                  objects:(__unsafe_unretained id [])stackbuf
                                    count:(NSUInteger)len {
    NSUInteger start = state->state,
               count = 0;

    for (NSUInteger i = 0; i < len && start + count < [self count]; i++) {
        stackbuf[i] = self[i + start];
        count++;
    }
    state->state += count;

    state->itemsPtr     = stackbuf;
    state->mutationsPtr = &mutationState;

    return count;
}

- (void)save {
    [self.article.dataStore saveImageList:self];
}

@end
