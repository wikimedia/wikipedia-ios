//
//  MWKSection+WMFSharing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSection+WMFSharing.h"
#import "NSString+WMFHTMLParsing.h"
#import <hpple/TFHpple.h>
#import "WikipediaAppUtils.h"

@implementation MWKSection (WMFSharing)

/// @return The text from the first `<p>` tag in the receiver's `text`.
- (NSString*)shareSnippet {
    /*
       HAX: TFHpple implicitly wraps its data in html/body tags, which we need to reference explicitly since we want the
       top-level <p> tag.
     */
    NSArray* xpathResults = [[TFHpple
                              hppleWithHTMLData:[self.text dataUsingEncoding:NSUTF8StringEncoding]]
                             searchWithXPathQuery:@"/html/body/p[1]//text()"];
    if (xpathResults) {
        NSString* shareSnippet =
            [[[xpathResults valueForKey:WMF_SAFE_KEYPATH([TFHppleElement new], raw)]
              componentsJoinedByString:@""]
             wmf_shareSnippetFromText];
        if (shareSnippet.length) {
            return shareSnippet;
        }
    }
    // fall back to text processing if HTML parsing fails
    NSString* shareSnippet = [self.text wmf_shareSnippetFromText];
    return shareSnippet.length ? shareSnippet : @"";
}

@end
