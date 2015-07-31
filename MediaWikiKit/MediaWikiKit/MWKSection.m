//
//  MWKSection.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import "WikipediaAppUtils.h"
#import "NSString+WMFHTMLParsing.h"
#import <hpple/TFHpple.h>
#import "WikipediaAppUtils.h"

NSString* const MWKSectionShareSnippetXPath = @"/html/body/p[not(.//span[@id='coordinates'])][1]//text()";

@interface MWKSection ()

@property (readwrite, strong, nonatomic) MWKTitle* title;
@property (readwrite, weak, nonatomic) MWKArticle* article;

@property (readwrite, copy, nonatomic) NSNumber* toclevel;      // optional
@property (readwrite, copy, nonatomic) NSNumber* level;         // optional; string in JSON, but seems to be number-safe?
@property (readwrite, copy, nonatomic) NSString* line;          // optional; HTML
@property (readwrite, copy, nonatomic) NSString* number;        // optional; can be "1.2.3"
@property (readwrite, copy, nonatomic) NSString* index;         // optional; can be "T-3" for transcluded sections
@property (readwrite, strong, nonatomic) MWKTitle* fromtitle; // optional
@property (readwrite, copy, nonatomic) NSString* anchor;        // optional
@property (readwrite, assign, nonatomic) int sectionId;           // required; -> id
@property (readwrite, assign, nonatomic) BOOL references;         // optional; marked by presence of key with empty string in JSON

@property (readwrite, copy, nonatomic) NSString* text;          // may be nil
@property (readwrite, strong, nonatomic) MWKImageList* images;    // ?????
@end

@implementation MWKSection

- (instancetype)initWithArticle:(MWKArticle*)article dict:(NSDictionary*)dict {
    self = [self initWithSite:article.site];
    if (self) {
        self.article = article;
        self.title   = article.title;

        self.toclevel   = [self optionalNumber:@"toclevel"   dict:dict];
        self.level      = [self optionalNumber:@"level"      dict:dict];  // may be a numeric string
        self.line       = [self optionalString:@"line"       dict:dict];
        self.number     = [self optionalString:@"number"     dict:dict];  // deceptively named, this must be a string
        self.index      = [self optionalString:@"index"      dict:dict];  // deceptively named, this must be a string
        self.fromtitle  = [self optionalTitle:@"fromtitle"  dict:dict];
        self.anchor     = [self optionalString:@"anchor"     dict:dict];
        self.sectionId  = [[self requiredNumber:@"id"         dict:dict] intValue];
        self.references = ([self optionalString:@"references" dict:dict] != nil);

        // Not present in .plist, loaded separately there
        self.text = [self optionalString:@"text"       dict:dict];
    }
    return self;
}

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    if (self.toclevel) {
        dict[@"toclevel"] = self.toclevel;
    }
    if (self.level) {
        dict[@"level"] = self.level;
    }
    if (self.line) {
        dict[@"line"] = self.line;
    }
    if (self.number) {
        dict[@"number"] = self.number;
    }
    if (self.index) {
        dict[@"index"] = self.index;
    }
    if (self.fromtitle) {
        dict[@"fromtitle"] = self.fromtitle.text;
    }
    if (self.anchor) {
        dict[@"anchor"] = self.anchor;
    }
    dict[@"id"] = @(self.sectionId);
    if (self.references) {
        dict[@"references"] = @"";
    }
    // Note: text is stored separately on disk
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (BOOL)isLeadSection {
    return (self.sectionId == 0);
}

- (MWKTitle*)sourceTitle {
    if (self.fromtitle) {
        // We probably came from a foreign template section!
        return self.fromtitle;
    } else {
        return self.title;
    }
}

- (NSString*)text {
    if (_text == nil) {
        _text = [self.article.dataStore sectionTextWithId:self.sectionId article:self.article];
    }
    return _text;
}

- (MWKImageList*)images {
    if (_images == nil) {
        _images = [self.article.dataStore imageListWithArticle:self.article section:self];
    }
    return _images;
}

- (void)save {
    [self.article.dataStore saveSection:self];
    if (_text != nil) {
        [self.article.dataStore saveSectionText:_text section:self];
    }
    if (_images != nil) {
        [self.images save];
    }
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKSection class]]) {
        return [self isEqualToSection:object];
    } else {
        return nil;
    }
}

- (BOOL)isEqualToSection:(MWKSection*)section {
    return WMF_IS_EQUAL(self.article, section.article)
           && self.sectionId == section.sectionId
           && self.references == section.references
           && WMF_EQUAL(self.toclevel, isEqualToNumber:, section.toclevel)
           && WMF_EQUAL(self.level, isEqualToNumber:, section.level)
           && WMF_EQUAL(self.line, isEqualToString:, section.line)
           && WMF_EQUAL(self.number, isEqualToString:, section.number)
           && WMF_EQUAL(self.index, isEqualToString:, section.index)
           && WMF_EQUAL(self.fromtitle, isEqual:, section.fromtitle)
           && WMF_EQUAL(self.anchor, isEqualToString:, section.anchor)
           && WMF_EQUAL(self.text, isEqualToString:, section.text)
           && WMF_EQUAL(self.images, isEqual:, section.images);
}

#pragma mark - Extraction

- (NSString*)shareSnippet {
    return [[self textForXPath:MWKSectionShareSnippetXPath] wmf_shareSnippetFromText];
}

- (NSString*)textForXPath:(NSString*)xpath {
    NSArray* xpathResults = [self elementsInTextMatchingXPath:xpath];
    if (xpathResults.count) {
        return [[xpathResults valueForKey:WMF_SAFE_KEYPATH([TFHppleElement new], raw)] componentsJoinedByString:@""];
    }
    return @"";
}

- (NSArray*)elementsInTextMatchingXPath:(NSString*)xpath {
    NSParameterAssert(xpath.length);
    if (!self.text) {
        DDLogWarn(@"Trying to query section text before downloaded. Section: %@", self);
        return nil;
    }
    return [[TFHpple hppleWithHTMLData:[self.text dataUsingEncoding:NSUTF8StringEncoding]] searchWithXPathQuery:xpath];
}

@end
