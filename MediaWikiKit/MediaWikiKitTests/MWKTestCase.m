//
//  MWKTestCase.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKTestCase.h"

@implementation MWKTestCase

- (NSData *)loadDataFile:(NSString *)name ofType:(NSString *)extension
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:extension];
    return [NSData dataWithContentsOfFile:path];
    
}

- (id)loadJSON:(NSString *)name
{
    NSData *data = [self loadDataFile:name ofType:@"json"];
    NSError *err = nil;
    id dictOrArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    assert(err == nil);
    assert(dictOrArray);
    return dictOrArray;
}

@end
