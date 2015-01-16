//
//  MWKImageMetadataItem.m
//  MediaWikiKit
//
//  Created by Brion on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImageMetadataItem.h"

@implementation MWKImageMetadataItem

-(instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        if (dict[@"value"] != nil) {
            _value = dict[@"value"];
        } else {
            _value = @"";
        }

        if (dict[@"source"] != nil) {
            _source = dict[@"source"];
        } else {
            _source = @"";
        }

        _hidden = (dict[@"hidden"] != nil);
    }
    return self;
}

-(NSDictionary *)dataExport
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"value"] = self.value;
    dict[@"source"] = self.source;
    if (self.hidden) {
        dict[@"hidden"] = @"";
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
