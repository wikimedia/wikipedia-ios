//
//  MWKArticle+ShareSnippet.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle+WMFSharing.h"
#import "NSString+WMFHTMLParsing.h"

@implementation MWKArticle (WMFSharing)

- (NSString*)shareSnippet {
    return [[self extractedLeadSectionText] wmf_shareSnippetFromText];
}

@end
