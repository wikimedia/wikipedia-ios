//
//  NSBundle+TestAssets.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSBundle+TestAssets.h"

@implementation NSBundle (TestAssets)

- (NSData*)wmf_dataFromContentsOfFile:(NSString *)filename ofType:(NSString *)type {
    NSError* error;
    NSData* data = [NSData dataWithContentsOfFile:[self pathForResource:filename ofType:@"json"]
                                          options:0
                                            error:&error];
    NSParameterAssert(!error);
    return data;
}

- (id)wmf_jsonFromContentsOfFile:(NSString*)filename {

    NSError* error;

    id json = [NSJSONSerialization JSONObjectWithData:[self wmf_dataFromContentsOfFile:filename ofType:@"json"]
                                              options:0
                                                error:&error];
    NSParameterAssert(!error);
    return json;
}

@end
