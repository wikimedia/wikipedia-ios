//
//  MWKSectionList.m
//  MediaWikiKit
//
//  Created by Brion on 12/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKSectionList {
    NSMutableArray *_sections;
    unsigned long mutationState;
}

- (NSUInteger)count
{
    return [_sections count];
}

- (MWKSection *)objectAtIndexedSubscript:(NSUInteger)idx
{
    return _sections[idx];
}

- (instancetype)initWithArticle:(MWKArticle *)article
{
    self = [self init];
    if (self) {
        _article = article;
        mutationState = 0;
        if (_sections == nil) {
            _sections = [@[] mutableCopy];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *path = [[self.article.dataStore pathForTitle:self.article.title] stringByAppendingPathComponent:@"sections"];
            NSArray *files = [fm contentsOfDirectoryAtPath:path error:nil];
            files = [files sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
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
            NSRegularExpression *redigits = [NSRegularExpression regularExpressionWithPattern:@"^\\d+$" options:0 error:nil];
            for (NSString *subpath in files) {
                NSString *filename = [subpath lastPathComponent];
                NSArray *matches = [redigits matchesInString:filename options:0 range:NSMakeRange(0, [filename length])];
                if (matches && [matches count]) {
                    int sectionId = [filename intValue];
                    _sections[sectionId] = [self.article.dataStore sectionWithId:sectionId article:self.article];
                }
            }
        }
    }
    return self;
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])stackbuf
                                    count:(NSUInteger)len
{
    NSUInteger start = state->state,
    count = 0;
    
    for (NSUInteger i = 0; i < len && start + count < [self count]; i++) {
        stackbuf[i] = self[i + start];
        count++;
    }
    state->state += count;
    
    state->itemsPtr = stackbuf;
    state->mutationsPtr = &mutationState;
    
    return count;
}

-(void)setSections:(NSArray *)sections;
{
    _sections = [sections mutableCopy];
}

-(void)save
{
    for (MWKSection *section in self) {
        [section save];
    }
}

@end
