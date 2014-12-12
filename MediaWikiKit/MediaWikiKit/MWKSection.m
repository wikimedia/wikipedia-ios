//
//  MWKSection.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKSection {
    NSString *_text;
    MWKImageList *_images;
}

-(instancetype)initWithArticle:(MWKArticle *)article dict:(NSDictionary *)dict
{
    self = [self initWithSite:article.site];
    if (self) {
        _article = article;
        _title = article.title;
        
        _toclevel   =  [self optionalNumber:@"toclevel"   dict:dict];
        _level      =  [self optionalNumber:@"level"      dict:dict]; // may be a numeric string
        _line       =  [self optionalString:@"line"       dict:dict];
        _number     =  [self optionalString:@"number"     dict:dict]; // deceptively named, this must be a string
        _index      =  [self optionalString:@"index"      dict:dict]; // deceptively named, this must be a string
        _fromtitle  =  [self optionalTitle: @"fromtitle"  dict:dict];
        _anchor     =  [self optionalString:@"anchor"     dict:dict];
        _sectionId  = [[self requiredNumber:@"id"         dict:dict] intValue];
        _references = ([self optionalString:@"references" dict:dict] != nil);
        
        // Not present in .plist, loaded separately there
        _text       =  [self optionalString:@"text"       dict:dict];
    }
    return self;
}

-(id)dataExport
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
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
        dict[@"fromtitle"] = [self.fromtitle prefixedText];
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

-(BOOL)isLeadSection
{
    return (self.sectionId == 0);
}

-(MWKTitle *)sourceTitle
{
    if (self.fromtitle) {
        // We probably came from a foreign template section!
        return self.fromtitle;
    } else {
        return self.title;
    }
}

-(NSString *)text
{
    if (_text == nil) {
        _text = [self.article.dataStore sectionTextWithId:self.sectionId article:self.article];
    }
    return _text;
}

-(MWKImageList *)images
{
    if (_images == nil) {
        _images = [self.article.dataStore imageListWithArticle:self.article section:self];
    }
    return _images;
}

-(void)save
{
    [self.article.dataStore saveSection:self];
    if (_text != nil) {
        [self.article.dataStore saveSectionText:_text section:self];
    }
    if (_images != nil) {
        [self.images save];
    }
}
@end
