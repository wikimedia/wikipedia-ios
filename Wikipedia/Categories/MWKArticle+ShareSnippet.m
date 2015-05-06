//
//  MWKArticle+ShareSnippet.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle+ShareSnippet.h"
#import "NSString+WMFHTMLParsing.h"
#import "MWKSection+WMFSharing.h"
#import <BlocksKit/BlocksKit.h>

@implementation MWKArticle (ShareSnippet)

/// @return The first non-empty `shareSnippet` from the receiver's `sections`.
- (NSString*)shareSnippet {
    for (MWKSection* section in self.sections) {
        NSString* snippet = section.shareSnippet;
        if (snippet.length) {
            return snippet;
        }
    }
    return @"";
}

@end
