//
//  MWKSavedPageEntry.m
//  MediaWikiKit
//
//  Created by Brion on 11/10/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKSavedPageEntry

-(instancetype)initWithTitle:(MWKTitle *)title
{
    self = [self initWithSite:title.site];
    if (self) {
        self.date = [[NSDate alloc] init];
    }
    return self;
}

-(id)initWithDict:(NSDictionary *)dict
{
    // Is this safe to run things before init?
    NSString *domain = [self requiredString:@"domain" dict:dict];
    NSString *language = [self requiredString:@"language" dict:dict];
    
    self = [self initWithSite:[MWKSite siteWithDomain:domain language:language]];
    if (self) {
        _title = [self requiredTitle:@"title" dict:dict];
    }
    return self;
}

-(id)dataExport
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"domain"] = self.site.domain;
    dict[@"language"] = self.site.language;
    dict[@"title"] = self.title.prefixedText;
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
