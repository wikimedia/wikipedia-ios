//
//  MWKSection+HTMLImageExtraction.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSection+HTMLImageExtraction.h"
#import <hpple/TFHpple.h>

@implementation MWKSection (HTMLImageParsing)

- (NSArray<TFHppleElement*>*)parseImageElements {
    // Reduce to img tags only. Causes TFHpple parse time to drop by ~50%.
    NSString* sectionImageTags = [self.text wmf_stringBySelectingHTMLImageTags];

    if (sectionImageTags.length == 0) {
        return @[];
    }

    TFHpple* sectionParser = [TFHpple hppleWithHTMLData:[sectionImageTags dataUsingEncoding:NSUTF8StringEncoding]];
    return [sectionParser searchWithXPathQuery:@"//img[starts-with(@src, \"//upload.wikimedia.org/\")]"];
}

@end

@implementation NSString (WMFHTMLImageParsing)

- (instancetype)wmf_stringBySelectingHTMLImageTags {
    if (self.length == 0) {
        return self;
    }
    static NSRegularExpression* regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"<img\\s+[^>]*>" options:0 error:nil];
    });

    NSArray<NSTextCheckingResult*>* matches = [regex matchesInString:self
                                                             options:0
                                                               range:NSMakeRange(0, self.length)];
    if (matches.count == 0) {
        return @"";
    }

    return [[matches bk_map:^NSString*(NSTextCheckingResult* textCheckingResult) {
        return [self substringWithRange:textCheckingResult.range];
    }] componentsJoinedByString:@""];
}

@end
