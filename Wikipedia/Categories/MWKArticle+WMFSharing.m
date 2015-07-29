//
//  MWKArticle+ShareSnippet.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle+WMFSharing.h"

@implementation MWKArticle (WMFSharing)

- (NSString*)shareSnippet {
    return [self extractedLeadSectionText];
}

@end
