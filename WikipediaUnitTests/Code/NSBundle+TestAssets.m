//
//  NSBundle+TestAssets.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSBundle+TestAssets.h"

@implementation NSBundle (TestAssets)

- (NSString*)wmf_stringFromContentsOfFile:(NSString*)filename ofType:(NSString*)type {
    NSError* error;
    NSString* string = [NSString stringWithContentsOfFile:[self pathForResource:filename ofType:type]
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];
    NSAssert(!error, @"Unexpected error reading test fixture: %@.%@, %@", filename, type, error);
    return string;
}

- (NSData*)wmf_dataFromContentsOfFile:(NSString*)filename ofType:(NSString*)type {
    NSError* error;
    NSData* data = [NSData dataWithContentsOfFile:[self pathForResource:filename ofType:type]
                                          options:0
                                            error:&error];
    NSAssert(!error, @"Unexpected error reading test fixture: %@.%@, %@", filename, type, error);
    return data;
}

- (id)wmf_jsonFromContentsOfFile:(NSString*)filename {
    NSError* error;
    id json = [NSJSONSerialization JSONObjectWithData:[self wmf_dataFromContentsOfFile:filename ofType:@"json"]
                                              options:NSJSONReadingMutableContainers
                                                error:&error];
    NSAssert(!error, @"Error reading JSON data from filename %@: %@", filename, error);
    return json;
}

@end
