//
//  MWKArticle+ShareSnippet.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle+ShareSnippet.h"
#import "NSString+WMFHTMLParsing.h"
#import <BlocksKit/BlocksKit.h>

@implementation MWKArticle (ShareSnippet)

- (NSString*)shareSnippet {
    NSString* heuristicText;
    for (MWKSection* section in self.sections) {
        heuristicText = [section.text wmf_shareSnippetFromHTML];
        if (heuristicText) {
            return heuristicText;
        }
    }
    for (MWKSection* section in self.sections) {
        heuristicText = [section.text wmf_shareSnippetFromText];
        if (heuristicText) {
            return heuristicText;
        }
    }
    return @"";
}

@end
