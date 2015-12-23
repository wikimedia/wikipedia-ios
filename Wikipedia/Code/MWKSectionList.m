//
//  MWKSectionList.m
//  MediaWikiKit
//
//  Created by Brion on 12/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSectionList.h"
#import "MediaWikiKit.h"
#import "WikipediaAppUtils.h"


@interface MWKSection (MWKSectionHierarchyBuilder)

@end

@implementation MWKSection (MWKSectionHierarchyBuilder)

- (BOOL)isOneLevelAboveSection:(MWKSection*)section {
    NSParameterAssert(section.level);
    NSParameterAssert(self.level);
    return section.level.integerValue - self.level.integerValue == 1;
}

- (BOOL)isAtSameLevelAsSection:(MWKSection*)section {
    NSParameterAssert(section.level);
    NSParameterAssert(self.level);
    return [section.level isEqualToNumber:self.level];
}

- (BOOL)isAtLevelAboveSection:(MWKSection*)section {
    NSParameterAssert(section.level);
    NSParameterAssert(self.level);
    return [section.level compare:self.level] == NSOrderedDescending;
}

@end


@interface MWKSectionList ()

@property (strong, nonatomic) NSArray* sections;
@property (readwrite, weak, nonatomic) MWKArticle* article;
@property (assign, nonatomic) unsigned long mutationState;

@end

@implementation MWKSectionList
@synthesize sections = _sections;

- (NSUInteger)count {
    return [self.sections count];
}

- (MWKSection*)objectAtIndexedSubscript:(NSUInteger)idx {
    return self.sections[idx];
}

- (instancetype)initWithArticle:(MWKArticle*)article sections:(NSArray*)sections {
    self = [self initWithArticle:article];
    if (self) {
        self.sections = sections;
    }
    return self;
}

- (instancetype)initWithArticle:(MWKArticle*)article {
    self = [self init];
    if (self) {
        self.article       = article;
        self.mutationState = 0;
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
    return WMF_EQUAL(self.article.title, isEqualToTitle:, sectionList.article.title)
           && WMF_EQUAL(self.sections, isEqualToArray:, [sectionList sections]);
}

- (NSArray*)sections {
    if (!_sections) {
        self.sections = [self sectionsFromDataStore];
    }
    return _sections;
}

- (void)setSections:(NSArray*)sections {
    _sections = [sections copy];
    [self buildSectionHierarchy];
}

- (NSArray*)sectionsFromDataStore {
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

    NSMutableArray* sections      = [[NSMutableArray alloc] init];
    NSRegularExpression* redigits = [NSRegularExpression regularExpressionWithPattern:@"^\\d+$" options:0 error:nil];
    @try {
        for (NSString* subpath in files) {
            NSString* filename = [subpath lastPathComponent];
            NSArray* matches   = [redigits matchesInString:filename options:0 range:NSMakeRange(0, [filename length])];
            if (matches && [matches count]) {
                MWKSection* section = [self.article.dataStore sectionWithId:filename.intValue
                                                                    article:self.article];
                NSParameterAssert(section);
                [sections addObject:section];
            }
        }
    }@catch (NSException* e) {
        NSLog(@"Failed to import sections at path %@, leaving list empty.", path);
        [sections removeAllObjects];
    }
    return sections;
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

- (NSArray*)entries {
    return self.sections;
}

#pragma mark - Hierarchy

- (void)buildSectionHierarchy {
    __block MWKSection* currentParent = nil;
    [self.sections makeObjectsPerformSelector:@selector(removeAllChildren)];
    [self.sections enumerateObjectsUsingBlock:^(MWKSection* currentSection, NSUInteger idx, BOOL* stop) {
        if (!currentSection.level) {
            currentParent = nil;
            return;
        }
        if ([currentParent isAtLevelAboveSection:currentSection]) {
            MWKSection* lastChild = currentParent.children.lastObject;
            if ([lastChild isAtSameLevelAsSection:currentSection] || ![lastChild isAtLevelAboveSection:currentSection]) {
                [currentParent addChild:currentSection];
            } else {
                [lastChild addChild:currentSection];
            }
        } else {
            currentParent = currentSection;
        }
    }];
}

- (NSArray*)topLevelSections {
    __block MWKSection* currentParent = nil;
    return [self.sections bk_reduce:[NSMutableArray arrayWithCapacity:self.sections.count]
                          withBlock:^NSMutableArray*(NSMutableArray* topLevelSections, MWKSection* section) {
        if (!section.level) {
            [topLevelSections addObject:section];
            currentParent = nil;
        } else if (currentParent == nil || ![currentParent isAtLevelAboveSection:section]) {
            currentParent = section;
            [topLevelSections addObject:section];
        }
        return topLevelSections;
    }];
}

@end
