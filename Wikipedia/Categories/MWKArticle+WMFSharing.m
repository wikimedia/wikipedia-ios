//
//  MWKArticle+ShareSnippet.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle+WMFSharing.h"
#import "NSString+WMFHTMLParsing.h"
#import "MWKSectionList.h"
#import "MWKSection.h"

#define MWKArticleMainPageLeadingHTMLXPath @"/html/body/div/div/p[1]"
static NSString* const MWKArticleMainPageLeadingTextXPath = MWKArticleMainPageLeadingHTMLXPath "//text()";

@implementation MWKArticle (WMFSharing)

- (NSString*)firstNonEmptyResultFromIteratingSectionsWithBlock:(NSString*(^)(MWKSection*))block {
    NSString* result;
    for (MWKSection* section in self.sections) {
        result = block(section);
        if (result) {
            return result;
        }
    }
    return @"";
}

- (NSString*)shareSnippet {
    if ([self isMain]) {
        return [self firstNonEmptyResultFromIteratingSectionsWithBlock:^NSString*(MWKSection* section) {
            return [[section textForXPath:MWKArticleMainPageLeadingTextXPath] wmf_shareSnippetFromText];
        }];
    } else {
        return [self firstNonEmptyResultFromIteratingSectionsWithBlock:^NSString*(MWKSection* section) {
            return [section shareSnippet];
        }];
    }
}

@end
