//
//  MWKImage.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "UIKit/UIKit.h"

#import "MediaWikiKit.h"

@implementation MWKImage

-(instancetype)initWithTitle:(MWKTitle *)title sourceURL:(NSString *)url
{
    self = [super initWithSite:title.site];
    if (self) {
        _title = title;
        _sourceURL = [url copy];

        _dateLastAccessed = nil;
        _dateRetrieved = nil;
        _mimeType = nil;
        _width = nil;
        _height = nil;
    }
    return self;
}

-(instancetype)initWithTitle:(MWKTitle *)title dict:(NSDictionary *)dict
{
    NSString *sourceURL = [self requiredString:@"sourceURL" dict:dict];
    self = [self initWithTitle:title sourceURL:sourceURL];
    if (self) {
        _dateLastAccessed = [self optionalDate:@"dateLastAccessed" dict:dict];
        _dateRetrieved = [self optionalDate:@"dateRetrieved" dict:dict];
        _mimeType = [self optionalString:@"mimeType" dict:dict];
        _width = [self optionalNumber:@"width" dict:dict];
        _height = [self optionalNumber:@"height" dict:dict];
    }
    return self;
}

-(NSString *)extension
{
    return [self.sourceURL pathExtension];
}

-(NSString *)fileName
{
    return [self.sourceURL lastPathComponent];
}

-(NSString *)fileNameNoSizePrefix
{
    return self.fileName; // @FIXME IMPLEMENT
}

-(id)dataExport
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"sourceURL"] = self.sourceURL;
    if (self.dateLastAccessed) {
        dict[@"dateLastAccessed"] = self.dateLastAccessed;
    }
    if (self.dateRetrieved) {
        dict[@"dateRetrieved"] = self.dateRetrieved;
    }
    if (self.mimeType) {
        dict[@"mimeType"] = self.mimeType;
    }
    if (self.width) {
        dict[@"width"] = self.width;
    }
    if (self.height) {
        dict[@"height"] = self.height;
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

-(void)updateWithData:(NSData *)data mimeType:(NSString *)mimeType
{
    _dateRetrieved = [[NSDate alloc] init];
    _dateLastAccessed = [[NSDate alloc] init];
    _mimeType = [mimeType copy];
    
    UIImage *img = [UIImage imageWithData:data scale:1.0];
    _width = [NSNumber numberWithInt:img.size.width];
    _height = [NSNumber numberWithInt:img.size.height];
}

-(void)updateLastAccessed
{
    _dateLastAccessed = [[NSDate alloc] init];
}

@end
