//
//  MWKSectionList.m
//  MediaWikiKit
//
//  Created by Brion on 12/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSectionList_Private.h"
#import "MediaWikiKit.h"
#import "WikipediaAppUtils.h"

@interface MWKSectionList ()

@property (readwrite, weak, nonatomic) MWKArticle* article;
@property (assign, nonatomic) unsigned long mutationState;

@end

@implementation MWKSectionList

- (NSUInteger)count {
    return [self.sections count];
}

- (MWKSection*)objectAtIndexedSubscript:(NSUInteger)idx {
    return self.sections[idx];
}

- (instancetype)initWithArticle:(MWKArticle*)article sections:(NSArray*)sections {
    self = [self initWithArticle:article];
    if (self) {
        self.sections = [sections mutableCopy];
    }
    return self;
}

- (instancetype)initWithArticle:(MWKArticle*)article {
    self = [self init];
    if (self) {
        self.article       = article;
        self.mutationState = 0;
        self.sections      = [NSMutableArray array];
        [self importSectionsFromDisk];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKSectionList class]]) {
        return [self isEqualToSectionList:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToSectionList:(MWKSectionList*)sectionList {
    return WMF_EQUAL(self.article, isEqualToArticle:, [sectionList article])
           && WMF_EQUAL(self.sections, isEqualToArray:, [sectionList sections]);
}

- (void)importSectionsFromDisk {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* path    = [[self.article.dataStore pathForTitle:self.article.title] stringByAppendingPathComponent:@"sections"];

    NSArray* files = [fm contentsOfDirectoryAtPath:path error:nil];
    files = [files sortedArrayUsingComparator:^NSComparisonResult (NSString* obj1, NSString* obj2) {
        int sectionId1 = [obj1 intValue];
        int sectionId2 = [obj2 intValue];
        if (sectionId1 < sectionId2) {
            return NSOrderedAscending;
        } else if (sectionId1 == sectionId2) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];

    NSRegularExpression* redigits = [NSRegularExpression regularExpressionWithPattern:@"^\\d+$" options:0 error:nil];
    @try {
        for (NSString* subpath in files) {
            NSString* filename = [subpath lastPathComponent];
            NSArray* matches   = [redigits matchesInString:filename options:0 range:NSMakeRange(0, [filename length])];
            if (matches && [matches count]) {
                [self readAndInsertSection:[filename intValue]];
            }
        }
    }@catch (NSException* e) {
        NSLog(@"Failed to import sections at path %@, leaving list empty.", path);
        [self.sections removeAllObjects];
    }
}

- (void)readAndInsertSection:(int)sectionId {
    self.sections[sectionId] = [self.article.dataStore sectionWithId:sectionId article:self.article];
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
    state->mutationsPtr = &_mutationState;

    return count;
}

- (void)save {
    for (MWKSection* section in self) {
        [section save];
    }
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"%@ { \n"
            "\t sections: %@ \n"
            "}", [self description], self.sections];
}

- (MWKSection*)firstNonEmptySection {
    for (MWKSection* section in self.sections) {
        if (section.text.length) {
            return section;
        }
    }
    return nil;
}

@end
