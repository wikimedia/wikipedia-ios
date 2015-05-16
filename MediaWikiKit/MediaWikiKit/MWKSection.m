//
//  MWKSection.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

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
        dict[@"fromtitle"] = self.fromtitle.prefixedText;
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

@end
