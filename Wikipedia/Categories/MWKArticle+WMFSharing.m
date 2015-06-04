//
//  MWKArticle+ShareSnippet.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle+WMFSharing.h"
#import "NSString+WMFHTMLParsing.h"
#import "MWKSection+WMFSharing.h"
#import <BlocksKit/BlocksKit.h>

@implementation MWKArticle (WMFSharing)

- (NSString*)shareSnippet {
    for (MWKSection* section in self.sections) {
        NSString* snippet = [self isMain] ?
                            [section shareSnippetFromTextUsingXpath : @"/html/body/div/div/p[1]//text()"]
                            :[section shareSnippet];
        if (snippet.length) {
            return snippet;
        }
    }
    return @"";
}

@end
