//
//  MWKSection.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKSection

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
        _sectionId  = [[self requiredNumber:@"id"         dict:dict] intValue];
        _references = ([self optionalString:@"references" dict:dict] != nil);
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
        dict[@"number"] = self.index;
    }
    if (self.fromtitle) {
        dict[@"fromtitle"] = [self.fromtitle prefixedText];
    }
    dict[@"id"] = @(self.sectionId);
    if (self.references) {
        dict[@"references"] = @"";
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

-(BOOL)isLeadSection
{
    return (self.sectionId == 0);
}

@end
